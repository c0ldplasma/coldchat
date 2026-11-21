import 'dart:io';

import 'package:coldchat/api/betterttv/betterttv.dart';
import 'package:coldchat/api/betterttv/betterttv_socket.dart';
import 'package:coldchat/data/badge_users.dart';
import 'package:coldchat/data/custom_badge.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/data/repositories/emote_badge_cache_repository.dart';
import 'package:coldchat/providers/badge_provider.dart';
import 'package:coldchat/providers/betterttv.dart';
import 'package:coldchat/providers/emote_provider.dart';
import 'package:coldchat/providers/provider.dart';
import 'package:coldchat/tmi/cache.dart';
import 'package:coldchat/tmi/client/chat_globals.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../api/fake_api.dart';

/// A provider whose global emotes, badges and user badges are whatever the test sets, or an error when [fails].
class _FakeProvider extends Provider with EmoteProvider, BadgeProvider {
  @override
  final String name;

  _FakeProvider(this.name);

  @override
  String? get description => null;

  bool fails = false;
  List<Emote> emotes = [];
  List<CustomBadge> badges = [];
  List<BadgeUsers> badgeHolders = [];

  Future<T> _answer<T>(T value) async => fails ? throw Exception('$name is down') : value;

  @override
  Future<List<Emote>> globalEmotes() => _answer(emotes);

  @override
  Future<List<CustomBadge>> globalBadges() => _answer(badges);

  @override
  Future<List<BadgeUsers>> globalUserBadges() => _answer(badgeHolders);

  Emote emote(String emoteName) =>
      Emote(id: '$name-$emoteName', name: emoteName, mipmap: const ['url'], provider: this);

  CustomBadge badge(String id) => CustomBadge(id: id, name: id, mipmap: const ['url'], provider: this);
}

/// A cache that only records the BetterTTV Pro badges saved to it.
class _RecordingCache implements EmoteBadgeCache {
  final List<Map<String, String>> savedBttvProBadges = [];

  @override
  Map<String, String> loadBttvProBadges() => const {};

  @override
  List<Emote> loadEmotes(String key) => const [];

  @override
  List<CustomBadge> loadBadges(String key) => const [];

  @override
  List<BadgeUsers> loadUserBadges(String key) => const [];

  @override
  Future<void> saveBttvProBadges(Map<String, String> badgeUrls) async => savedBttvProBadges.add(badgeUrls);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _bttv = BetterTTVProvider(BttvApi(offlineApi()));

void main() {
  late Directory tempDir;
  late _FakeProvider seventv;
  late _FakeProvider ffz;
  late int badgeRebuilds;
  late List<String> userRebuilds;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_chat_globals_test');
    Hive.init(tempDir.path);
    seventv = _FakeProvider('7TV');
    ffz = _FakeProvider('FrankerFaceZ');
    badgeRebuilds = 0;
    userRebuilds = [];
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<EmoteBadgeCache> openCache() async =>
      EmoteBadgeCache(repository: await EmoteBadgeCacheRepository.open(), providers: [seventv, ffz, _bttv]);

  ChatGlobals globals({EmoteBadgeCache? cache}) {
    final globals = ChatGlobals(
      providers: [seventv, ffz, _bttv],
      cache: cache,
      onBadgesChanged: () => badgeRebuilds++,
      onUserBadgeChanged: userRebuilds.add,
    );
    addTearDown(globals.close);
    return globals;
  }

  group('refreshing', () {
    test('merges the global emotes of every provider', () async {
      seventv.emotes = [seventv.emote('Clap')];
      ffz.emotes = [ffz.emote('LuL'), ffz.emote('OMEGALUL')];
      final g = globals();
      // BetterTTV's real API is offline here, so it adds nothing.
      await g.refreshEmotes();

      expect(g.emotes.state.map((e) => e.name), ['Clap', 'LuL', 'OMEGALUL']);
    });

    test('a failing provider keeps its earlier emotes and does not drop the others', () async {
      seventv.emotes = [seventv.emote('Clap')];
      ffz.emotes = [ffz.emote('LuL')];
      final g = globals();
      await g.refreshEmotes();

      ffz.fails = true;
      seventv.emotes = [seventv.emote('Clap'), seventv.emote('EZ')];
      await g.refreshEmotes();

      expect(g.emotes.state.map((e) => e.name), ['Clap', 'EZ', 'LuL']);
    });

    test('rebuilds the messages only when the badges or their holders changed', () async {
      seventv.badges = [seventv.badge('7tv-sub')];
      final g = globals();
      await g.refreshBadges();
      expect(g.badges.state.map((b) => b.id), ['7tv-sub']);
      expect(badgeRebuilds, 1);

      await g.refreshBadges();
      expect(badgeRebuilds, 1);

      seventv.badgeHolders = [
        BadgeUsers(badge: seventv.badge('7tv-sub'), users: ['1']),
      ];
      await g.refreshUserBadges();
      expect(g.userBadges.badgesOf('1').map((b) => b.id), ['7tv-sub']);
      expect(badgeRebuilds, 2);

      ffz.fails = true;
      await g.refreshUserBadges();
      expect(g.userBadges.badgesOf('1').map((b) => b.id), ['7tv-sub']);
      expect(badgeRebuilds, 2);
    });
  });

  group('the cache', () {
    test('saves what was refreshed and shows it on the next launch before any request', () async {
      seventv.emotes = [seventv.emote('Clap')];
      ffz.badges = [ffz.badge('ffz-bot')];
      seventv.badgeHolders = [
        BadgeUsers(badge: seventv.badge('7tv-sub'), users: ['1']),
      ];
      final first = globals(cache: await openCache());
      await first.refreshEmotes();
      await first.refreshBadges();
      await first.refreshUserBadges();
      await Future<void>.delayed(Duration.zero);

      final next = globals(cache: await openCache());

      expect(next.emotes.state.map((e) => e.name), ['Clap']);
      expect(next.badges.state.map((b) => b.id), ['ffz-bot']);
      expect(next.userBadges.badgesOf('1').map((b) => b.id), ['7tv-sub']);
    });

    test('keeps the Twitch emotes per account', () async {
      final cache = await openCache();
      final g = globals(cache: cache);
      g.setTwitchUserEmotes('1', [seventv.emote('Kappa')]);
      await Future<void>.delayed(Duration.zero);

      g.showCachedTwitchUserEmotes('2');
      expect(g.twitchUserEmotes.state, isEmpty);
      g.showCachedTwitchUserEmotes('1');
      expect(g.twitchUserEmotes.state.map((e) => e.name), ['Kappa']);
      g.showCachedTwitchUserEmotes(null);
      expect(g.twitchUserEmotes.state, isEmpty);
    });

    test('loads the saved BetterTTV Pro badges', () async {
      final cache = await openCache();
      await cache.saveBttvProBadges({'1': 'https://cdn.betterttv.net/badge.png'});

      final g = globals(cache: cache);

      expect(g.bttvProBadges['1']?.mipmap, ['https://cdn.betterttv.net/badge.png']);
      expect(g.bttvProBadges['1']?.provider, same(_bttv));
    });
  });

  group('BetterTTV Pro badges', () {
    test('a lookup adds, updates and removes a badge and rebuilds that user\'s messages', () {
      final g = globals();

      g.onBttvLookupUser(BetterTTVProBadge(userId: '1', url: 'a.png'));
      expect(g.bttvProBadges['1']?.mipmap, ['a.png']);
      expect(userRebuilds, ['1']);

      final badge = g.bttvProBadges['1'];
      g.onBttvLookupUser(BetterTTVProBadge(userId: '1', url: 'a.png'));
      expect(g.bttvProBadges['1'], same(badge));
      expect(userRebuilds, ['1']);

      g.onBttvLookupUser(BetterTTVProBadge(userId: '1', url: 'b.png'));
      expect(g.bttvProBadges['1']?.mipmap, ['b.png']);
      expect(userRebuilds, ['1', '1']);

      g.onBttvLookupUser(BetterTTVProBadge(userId: '1', url: null));
      expect(g.bttvProBadges, isEmpty);
      expect(userRebuilds, ['1', '1', '1']);
    });

    test('keeps at most ${ChatGlobals.maxBttvProBadges}, dropping the user seen longest ago', () {
      final g = globals();
      for (var i = 0; i < ChatGlobals.maxBttvProBadges; i++) {
        g.onBttvLookupUser(BetterTTVProBadge(userId: '$i', url: 'a.png'));
      }
      // Seen again, so it's the newest now.
      g.onBttvLookupUser(BetterTTVProBadge(userId: '0', url: 'a.png'));
      g.onBttvLookupUser(BetterTTVProBadge(userId: 'new', url: 'a.png'));

      expect(g.bttvProBadges, hasLength(ChatGlobals.maxBttvProBadges));
      expect(g.bttvProBadges.containsKey('0'), isTrue);
      expect(g.bttvProBadges.containsKey('1'), isFalse);
      expect(g.bttvProBadges.keys.last, 'new');
    });

    test('are saved 5 seconds after the last lookup', () {
      fakeAsync((async) {
        final cache = _RecordingCache();
        final g = ChatGlobals(providers: [_bttv], cache: cache, onBadgesChanged: () {}, onUserBadgeChanged: (_) {});
        g.onBttvLookupUser(BetterTTVProBadge(userId: '1', url: 'a.png'));
        async.elapse(const Duration(seconds: 4));
        g.onBttvLookupUser(BetterTTVProBadge(userId: '2', url: 'b.png'));
        async.elapse(const Duration(seconds: 4));
        expect(cache.savedBttvProBadges, isEmpty);
        async.elapse(const Duration(seconds: 1));
        expect(cache.savedBttvProBadges, [
          {'1': 'a.png', '2': 'b.png'},
        ]);
      });
    });
  });
}
