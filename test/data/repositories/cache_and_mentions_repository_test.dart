import 'dart:io';

import 'package:coldchat/api/seventv/seventv.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/data/repositories/emote_badge_cache_repository.dart';
import 'package:coldchat/data/repositories/seen_mentions_repository.dart';
import 'package:coldchat/sources/seventv_source.dart';
import 'package:coldchat/tmi/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../api/fake_api.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_cache_repository_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> reopen() async {
    await Hive.close();
    Hive.init(tempDir.path);
  }

  group('EmoteBadgeCacheRepository', () {
    test('uses the existing box and keys', () {
      expect(EmoteBadgeCacheRepository.boxName, 'EmoteBadgeCache');
      expect(EmoteBadgeCacheRepository.globalEmotesKey, 'globalEmotes');
      expect(EmoteBadgeCacheRepository.globalBadgesKey, 'globalBadges');
      expect(EmoteBadgeCacheRepository.globalUserBadgesKey, 'globalUserBadges');
      expect(EmoteBadgeCacheRepository.bttvProBadgesKey, 'bttvProBadges');
      expect(EmoteBadgeCacheRepository.twitchUserEmotesKey('1'), 'twitchUserEmotes:1');
      expect(EmoteBadgeCacheRepository.channelEmotesKey('forsen'), 'channelEmotes:v2:forsen');
      expect(EmoteBadgeCacheRepository.channelBadgesKey('forsen'), 'channelBadges:v2:forsen');
      expect(EmoteBadgeCacheRepository.historyKey('forsen'), 'history:v2:forsen');
    });

    test('drops channel entries keyed the way versions before v2 did', () async {
      final box = await Hive.openBox<dynamic>('EmoteBadgeCache');
      await box.putAll({
        'channelEmotes:12345': '[]',
        'history:forsen': '[]',
        'channelEmotes:v2:forsen': '[]',
        'globalEmotes': '[]',
      });

      EmoteBadgeCacheRepository(box);
      await pumpEventQueue();

      expect(box.keys.toSet(), {'channelEmotes:v2:forsen', 'globalEmotes'});
    });

    test('reads and writes JSON lists, and ignores what it cannot read', () async {
      final repository = await EmoteBadgeCacheRepository.open();
      final box = Hive.box<dynamic>('EmoteBadgeCache');

      await repository.writeJson('globalEmotes', [
        {'id': '1'},
      ]);
      expect(box.get('globalEmotes'), '[{"id":"1"}]');
      expect(repository.readList('globalEmotes'), [
        {'id': '1'},
      ]);

      await box.put('broken', '{not json');
      await box.put('map', '{"a": 1}');
      await box.put('number', 3);
      expect(repository.readList('broken'), isNull);
      expect(repository.readList('map'), isNull);
      expect(repository.readList('number'), isNull);
      expect(repository.readList('missing'), isNull);
    });

    test('stores BetterTTV Pro badges and history', () async {
      var repository = await EmoteBadgeCacheRepository.open();
      await repository.saveBttvProBadges({'1': 'https://example.com/1.png'});
      await repository.saveHistory('forsen', ['line 1', 'line 2']);

      await reopen();
      repository = await EmoteBadgeCacheRepository.open();

      expect(repository.loadBttvProBadges(), {'1': 'https://example.com/1.png'});
      expect(repository.loadHistory('forsen'), ['line 1', 'line 2']);
      expect(repository.loadHistory('nymn'), isEmpty);
    });

    test('evicts the channel used longest ago beyond the limit, across launches', () async {
      var repository = await EmoteBadgeCacheRepository.open();
      for (var i = 0; i < EmoteBadgeCacheRepository.maxCachedChannels; i++) {
        await repository.saveHistory('channel$i', ['line']);
      }
      // Using channel0 again makes channel1 the oldest.
      await repository.saveHistory('channel0', ['line']);

      await reopen();
      repository = await EmoteBadgeCacheRepository.open();
      await repository.saveHistory('new', ['line']);
      await pumpEventQueue();

      expect(repository.loadHistory('channel0'), ['line']);
      expect(repository.loadHistory('channel1'), isEmpty);
      expect(repository.loadHistory('channel2'), ['line']);
      expect(repository.loadHistory('new'), ['line']);
    });

    test('EmoteBadgeCache turns cached emotes back into emotes of known sources', () async {
      final source = SevenTvSource(SevenTvApi(offlineApi()));
      final cache = EmoteBadgeCache(repository: await EmoteBadgeCacheRepository.open(), sources: [source]);
      final emote = Emote(
        id: 'e1',
        name: 'Pog',
        mipmap: const ['https://example.com/1x'],
        source: source,
        category: 'Ronni',
        categoryIcon: 'https://example.com/badge',
        ownerId: '42',
      );

      await cache.saveChannelEmotes('forsen', [emote]);
      await reopen();
      final reloaded = EmoteBadgeCache(repository: await EmoteBadgeCacheRepository.open(), sources: [source]);

      final [loaded] = reloaded.loadChannelEmotes('forsen');
      expect((loaded.id, loaded.name, loaded.source), ('e1', 'Pog', source));
      expect(loaded.mipmap, ['https://example.com/1x']);
      expect((loaded.category, loaded.categoryIcon, loaded.ownerId), ('Ronni', 'https://example.com/badge', '42'));
      // An emote of a source that isn't there anymore is dropped.
      final withoutSource = EmoteBadgeCache(repository: await EmoteBadgeCacheRepository.open(), sources: []);
      expect(withoutSource.loadChannelEmotes('forsen'), isEmpty);
    });
  });

  group('SeenMentionsRepository', () {
    test('uses the existing box', () {
      expect(SeenMentionsRepository.boxName, 'SeenMentions');
    });

    test('remembers seen mentions across launches', () async {
      var repository = await SeenMentionsRepository.open();
      repository.markSeen('a', now: DateTime.fromMillisecondsSinceEpoch(5));
      repository.markSeen('');
      await pumpEventQueue();

      await reopen();
      repository = await SeenMentionsRepository.open();

      expect(repository.contains('a'), isTrue);
      expect(repository.contains('b'), isFalse);
      expect(Hive.box<dynamic>('SeenMentions').toMap(), {'a': 5});
    });

    test('marking one that was seen already keeps when it was first seen', () async {
      final repository = await SeenMentionsRepository.open();
      repository.markSeen('a', now: DateTime.fromMillisecondsSinceEpoch(5));
      await pumpEventQueue();
      repository.markSeen('a', now: DateTime.fromMillisecondsSinceEpoch(9));
      await pumpEventQueue();

      expect(Hive.box<dynamic>('SeenMentions').get('a'), 5);
    });

    test('forgets the oldest beyond the limit', () async {
      final box = await Hive.openBox<dynamic>('SeenMentions');
      await box.putAll({
        for (var i = 0; i < SeenMentionsRepository.maxEntries; i++) 'm$i': 1000 + i,
      });
      final repository = SeenMentionsRepository(box);

      repository.markSeen('newest', now: DateTime.fromMillisecondsSinceEpoch(100000));
      await pumpEventQueue();
      repository.markSeen('newer', now: DateTime.fromMillisecondsSinceEpoch(100001));
      await pumpEventQueue();

      expect(box.length, SeenMentionsRepository.maxEntries);
      expect(repository.contains('m0'), isFalse);
      expect(repository.contains('newest'), isTrue);
      expect(repository.contains('newer'), isTrue);
    });
  });
}
