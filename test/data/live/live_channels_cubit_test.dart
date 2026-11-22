import 'dart:async';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/api/twitch/twitch_profile.dart';
import 'package:coldchat/data/live/live_channels_cubit.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../api/fake_api.dart';

void main() {
  late HelixApi? helix;
  late List<String> joined;
  late StreamController<Object?> channelChanges;
  late ChangeNotifier accountChanges;
  late Set<String> liveNow;
  late List<List<String>> asked;
  late bool failNext;

  LiveChannelsCubit create() => LiveChannelsCubit(
    helix: () => helix,
    logins: () => joined,
    channelChanges: channelChanges.stream,
    accountChanges: accountChanges,
    liveLogins: (helix, logins) async {
      asked.add(logins);
      if (failNext) {
        failNext = false;
        throw Exception('Helix down');
      }
      return liveNow.intersection(logins.toSet());
    },
    watchLifecycle: false,
  );

  setUp(() {
    helix = HelixApi(offlineApi(), () => null);
    joined = ['#forsen', '#xqc', '#Nymn'];
    channelChanges = StreamController<Object?>.broadcast(sync: true);
    accountChanges = ChangeNotifier();
    liveNow = {'forsen'};
    asked = [];
    failNext = false;
  });

  tearDown(() async {
    await channelChanges.close();
    accountChanges.dispose();
  });

  test('asks right away about every joined channel, without # and lowercase', () {
    fakeAsync((async) {
      final cubit = create();
      async.flushMicrotasks();
      expect(asked, [
        ['forsen', 'xqc', 'nymn'],
      ]);
      expect(cubit.state, {'forsen'});
      unawaited(cubit.close());
    });
  });

  test('a streamer going live shows up at the next round', () {
    fakeAsync((async) {
      final cubit = create();
      async.flushMicrotasks();
      liveNow = {'forsen', 'xqc'};
      async.elapse(const Duration(seconds: 59));
      expect(cubit.state, {'forsen'});
      async.elapse(const Duration(seconds: 1));
      expect(cubit.state, {'forsen', 'xqc'});
      liveNow = {'xqc'};
      async.elapse(const Duration(seconds: 60));
      expect(cubit.state, {'xqc'});
      unawaited(cubit.close());
    });
  });

  test('joining a channel asks right away; leaving one drops it without asking', () {
    fakeAsync((async) {
      final cubit = create();
      async.flushMicrotasks();
      liveNow = {'forsen', 'vedal987'};
      joined = [...joined, '#vedal987'];
      channelChanges.add(null);
      async.flushMicrotasks();
      expect(asked, hasLength(2));
      expect(cubit.state, {'forsen', 'vedal987'});

      joined = ['#xqc', '#nymn', '#vedal987'];
      channelChanges.add(null);
      async.flushMicrotasks();
      expect(asked, hasLength(2));
      expect(cubit.state, {'vedal987'});
      unawaited(cubit.close());
    });
  });

  test("doesn't ask in the background, and asks as soon as the app is back", () {
    fakeAsync((async) {
      final cubit = create();
      async.flushMicrotasks();
      cubit.paused();
      async.elapse(const Duration(minutes: 5));
      expect(asked, hasLength(1));

      liveNow = {'xqc'};
      cubit.resumed();
      async.flushMicrotasks();
      expect(asked, hasLength(2));
      expect(cubit.state, {'xqc'});
      async.elapse(const Duration(seconds: 60));
      expect(asked, hasLength(3));
      unawaited(cubit.close());
    });
  });

  test('a failed request keeps the last answer', () {
    fakeAsync((async) {
      final cubit = create();
      async.flushMicrotasks();
      failNext = true;
      liveNow = {};
      async.elapse(const Duration(seconds: 60));
      expect(cubit.state, {'forsen'});
      async.elapse(const Duration(seconds: 60));
      expect(cubit.state, isEmpty);
      unawaited(cubit.close());
    });
  });

  test('without a login no channel is live; logging in asks again', () {
    fakeAsync((async) {
      final loggedIn = helix;
      helix = null;
      final cubit = create();
      async.flushMicrotasks();
      expect(asked, isEmpty);
      expect(cubit.state, isEmpty);

      helix = loggedIn;
      accountChanges.notifyListeners();
      async.flushMicrotasks();
      expect(cubit.state, {'forsen'});

      helix = null;
      accountChanges.notifyListeners();
      async.flushMicrotasks();
      expect(cubit.state, isEmpty);
      unawaited(cubit.close());
    });
  });

  test('an older answer arriving after a newer one is dropped', () {
    fakeAsync((async) {
      final answers = <Completer<Set<String>>>[];
      final cubit = LiveChannelsCubit(
        helix: () => helix,
        logins: () => joined,
        channelChanges: channelChanges.stream,
        accountChanges: accountChanges,
        liveLogins: (helix, logins) => (answers..add(Completer())).last.future,
        watchLifecycle: false,
      );
      unawaited(cubit.refresh());
      answers[1].complete({'xqc'});
      async.flushMicrotasks();
      answers[0].complete({'forsen'});
      async.flushMicrotasks();
      expect(cubit.state, {'xqc'});
      unawaited(cubit.close());
    });
  });

  test('liveLoginsFromHelix asks for at most 100 logins per request', () async {
    final requests = <Uri>[];
    final api = fakeApi((request) async {
      requests.add(request.url);
      return http.Response(
        '{"data": [{"id": "1", "user_id": "1", "user_login": "Forsen", "user_name": "forsen", '
        '"game_id": "", "game_name": "", "type": "live", "title": "", "viewer_count": 1, '
        '"started_at": "2026-11-22T12:00:00Z", "language": "en", "thumbnail_url": "", "tag_ids": [], '
        '"tags": [], "is_mature": false}], "pagination": {}}',
        200,
      );
    });
    final live = await liveLoginsFromHelix(
      HelixApi(
        api,
        () =>
            TokenData(clientId: 'c', login: 'ronni', scopes: const [], userId: '1', expiresAt: null, accessToken: 't'),
      ),
      [for (var i = 0; i < 150; i++) 'user$i'],
    );
    expect(requests, hasLength(2));
    expect(requests[0].queryParametersAll['user_login'], hasLength(100));
    expect(requests[1].queryParametersAll['user_login'], hasLength(50));
    expect(live, {'forsen'});
  });

  group('isChannelLive', () {
    TwitchProfile profile({required bool live}) => TwitchProfile(
      user: TwitchUser(id: '1', login: 'forsen', displayName: 'forsen', profileImageUrl: '', offlineImageUrl: null),
      followerCount: 0,
      stream: live
          ? TwitchLiveStream(
              title: '',
              gameName: '',
              gameBoxArtUrl: null,
              thumbnailUrl: '',
              viewerCount: 1,
              startedAt: DateTime(2026),
            )
          : null,
    );

    test('before the profile has loaded, the last round says', () {
      expect(isChannelLive(login: '#Forsen', profile: null, live: {'forsen'}), isTrue);
      expect(isChannelLive(login: '#forsen', profile: null, live: {'xqc'}), isFalse);
    });

    test('the freshly loaded profile wins over the last round', () {
      expect(isChannelLive(login: '#forsen', profile: profile(live: false), live: {'forsen'}), isFalse);
      expect(isChannelLive(login: '#forsen', profile: profile(live: true), live: const {}), isTrue);
    });
  });
}
