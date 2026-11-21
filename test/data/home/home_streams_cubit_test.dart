import 'dart:async';
import 'dart:convert';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/data/home/home_streams_cubit.dart';
import 'package:coldchat/data/twitch/stream_data.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../api/fake_api.dart';

TokenData _token(String login) => TokenData(
  clientId: 'client-id',
  login: login,
  scopes: const [],
  userId: 'id-$login',
  expiresAt: null,
  accessToken: 'token-$login',
);

Map<String, Object?> _stream(String login) => {
  'id': 's-$login',
  'user_id': 'u-$login',
  'user_login': login,
  'user_name': login.toUpperCase(),
  'game_id': '509658',
  'game_name': 'Just Chatting',
  'type': 'live',
  'title': 'hi',
  'viewer_count': 1000,
  'started_at': '2026-11-21T10:00:00Z',
  'language': 'en',
  'thumbnail_url': 'https://static-cdn.jtvnw.net/previews-ttv/live_user_$login-{width}x{height}.jpg',
  'tag_ids': <String>[],
  'tags': ['English'],
  'is_mature': false,
};

http.Response _streams(List<String> logins) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'data': [for (final login in logins) _stream(login)],
    }),
  ),
  200,
);

/// A request the test answers when it wants to.
class _Call {
  final http.Request request;
  final Completer<http.Response> answer = Completer();

  _Call(this.request);

  bool get recommended => request.url.queryParametersAll.containsKey('user_login');

  String get token => request.headers['Authorization']!;
}

class _AccountChanges extends ChangeNotifier {
  void changed() => notifyListeners();
}

void main() {
  late List<_Call> calls;
  late _AccountChanges accountChanges;
  late HelixApi? active;
  late DateTime now;
  late HomeStreamsCubit cubit;

  HelixApi helixFor(String login) {
    final token = _token(login);
    return HelixApi(
      fakeApi((request) {
        final call = _Call(request);
        calls.add(call);
        return call.answer.future;
      }),
      () => token,
    );
  }

  HomeStreamsCubit create() => HomeStreamsCubit(helix: () => active, accountChanges: accountChanges, now: () => now);

  // Answers the open calls: the recommended with [recommended], the top with [top] (an exception fails the call).
  Future<void> answerAll({Object recommended = const ['forsen'], Object top = const ['xqc']}) async {
    await pumpEventQueue();
    final open = calls.where((call) => !call.answer.isCompleted).toList();
    for (final call in open) {
      final answer = call.recommended ? recommended : top;
      if (answer is List<String>) {
        call.answer.complete(_streams(answer));
      } else {
        call.answer.completeError(answer);
      }
    }
    await pumpEventQueue();
  }

  List<String>? logins(List<StreamData>? streams) => streams?.map((s) => s.userLogin).toList();

  setUp(() {
    calls = [];
    accountChanges = _AccountChanges();
    active = null;
    now = DateTime(2026, 11, 21, 12);
  });

  tearDown(() async {
    await cubit.close();
    accountChanges.dispose();
  });

  test('without an account nothing is loaded', () async {
    cubit = create();
    await pumpEventQueue();

    expect(cubit.state.loggedIn, isFalse);
    expect(calls, isEmpty);

    cubit.homeShown();
    await cubit.refresh();
    expect(calls, isEmpty);
  });

  test('loads both lists for the active account', () async {
    active = helixFor('ronni');
    cubit = create();
    await pumpEventQueue();

    expect(cubit.state.loggedIn, isTrue);
    expect(cubit.state.recommended.isLoading, isTrue);
    expect(cubit.state.top.isLoading, isTrue);
    expect(calls, hasLength(2));

    await answerAll();
    expect(logins(cubit.state.recommended.streams), ['forsen']);
    expect(logins(cubit.state.top.streams), ['xqc']);
  });

  test('failed lists are marked failed', () async {
    active = helixFor('ronni');
    cubit = create();
    await answerAll(recommended: Exception('offline'), top: Exception('offline'));

    expect(cubit.state.recommended.failed, isTrue);
    expect(cubit.state.top.failed, isTrue);
    expect(cubit.state.top.streams, isNull);
  });

  test('an account switch reloads and drops the result of the old account still in flight', () async {
    active = helixFor('ronni');
    cubit = create();
    await pumpEventQueue();
    final oldCalls = List.of(calls);

    active = helixFor('other');
    accountChanges.changed();
    await pumpEventQueue();
    expect(calls, hasLength(4));
    expect(calls.skip(2).map((call) => call.token), everyElement('Bearer token-other'));
    expect(cubit.state.top.isLoading, isTrue);

    for (final call in oldCalls) {
      call.answer.complete(_streams(['old']));
    }
    await pumpEventQueue();
    expect(cubit.state.recommended.isLoading, isTrue);
    expect(cubit.state.top.isLoading, isTrue);

    await answerAll(top: ['new']);
    expect(logins(cubit.state.top.streams), ['new']);
  });

  test('logging out clears the lists and drops results in flight', () async {
    active = helixFor('ronni');
    cubit = create();
    await answerAll();

    unawaited(cubit.refresh());
    await pumpEventQueue();
    active = null;
    accountChanges.changed();
    await answerAll();

    expect(cubit.state.loggedIn, isFalse);
    expect(cubit.state.top.streams, isNull);
  });

  test('refresh completes once both lists are loaded and keeps the old lists meanwhile', () async {
    active = helixFor('ronni');
    cubit = create();
    await answerAll();

    var done = false;
    unawaited(cubit.refresh().then((_) => done = true));
    await pumpEventQueue();
    expect(logins(cubit.state.top.streams), ['xqc']);

    calls.last.answer.complete(_streams(calls.last.recommended ? ['forsen'] : ['new']));
    await pumpEventQueue();
    expect(done, isFalse);

    await answerAll(recommended: ['nymn']);
    expect(done, isTrue);
    expect(logins(cubit.state.recommended.streams), ['nymn']);
  });

  test('a failed reload keeps the lists already shown', () async {
    active = helixFor('ronni');
    cubit = create();
    await answerAll();

    unawaited(cubit.refresh());
    await pumpEventQueue();
    await answerAll(recommended: Exception('offline'), top: Exception('offline'));

    expect(logins(cubit.state.recommended.streams), ['forsen']);
    expect(logins(cubit.state.top.streams), ['xqc']);
  });

  test('showing the home tab reuses lists younger than 5 minutes and reloads older ones in the background', () async {
    active = helixFor('ronni');
    cubit = create();
    await answerAll();
    expect(calls, hasLength(2));

    now = now.add(const Duration(minutes: 4, seconds: 59));
    cubit.homeShown();
    await pumpEventQueue();
    expect(calls, hasLength(2));

    now = now.add(const Duration(seconds: 2));
    cubit.homeShown();
    await pumpEventQueue();
    expect(calls, hasLength(4));
    // The old lists stay visible while the new ones load: no spinner.
    expect(logins(cubit.state.top.streams), ['xqc']);
    expect(cubit.state.top.isLoading, isFalse);

    // Shown again while the reload is still running: no second reload.
    cubit.homeShown();
    await pumpEventQueue();
    expect(calls, hasLength(4));

    await answerAll(top: ['new']);
    expect(logins(cubit.state.top.streams), ['new']);

    // The reload restarted the 5 minutes.
    now = now.add(const Duration(minutes: 1));
    cubit.homeShown();
    await pumpEventQueue();
    expect(calls, hasLength(4));
  });

  test('showing the home tab after a failed load tries again', () async {
    active = helixFor('ronni');
    cubit = create();
    await answerAll(top: Exception('offline'));

    cubit.homeShown();
    await pumpEventQueue();
    expect(calls, hasLength(4));
  });
}
