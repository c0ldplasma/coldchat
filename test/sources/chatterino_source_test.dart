import 'dart:convert';
import 'dart:io';

import 'package:coldchat/api/chatterino/chatterino.dart';
import 'package:coldchat/data/repositories/emote_badge_cache_repository.dart';
import 'package:coldchat/sources/chatterino_source.dart';
import 'package:coldchat/tmi/cache.dart';
import 'package:coldchat/tmi/user_badges.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../api/fake_api.dart';

void main() {
  ChatterinoSource source(Object body) =>
      ChatterinoSource(ChatterinoApi(fakeApi((request) async => http.Response(jsonEncode(body), 200))));

  final response = {
    'badges': [
      {
        'tooltip': 'Chatterino Developer',
        'image1': 'https://fourtf.com/chatterino/badges/dev.png',
        'image2': 'https://fourtf.com/chatterino/badges/dev2x.png',
        'image3': 'https://fourtf.com/chatterino/badges/dev3x.png',
        'users': ['1', '2'],
      },
      {
        'tooltip': 'Chatterino Supporter',
        'image1': 'https://fourtf.com/chatterino/badges/supporter.png',
        'users': ['2'],
      },
      // Nothing to show: no tooltip, or no image.
      {
        'image1': 'https://fourtf.com/chatterino/badges/x.png',
        'users': ['3'],
      },
      {
        'tooltip': 'Chatterino Special Pepe Badge',
        'users': ['3'],
      },
    ],
  };

  test('maps the badge list to badges named after their tooltip, images smallest to largest', () async {
    final chatterino = source(response);

    final badges = await chatterino.globalUserBadges();

    expect(badges.map((b) => (b.badge.id, b.badge.name, b.users.join(','))), [
      ('chatterino-Chatterino Developer', 'Chatterino Developer', '1,2'),
      ('chatterino-Chatterino Supporter', 'Chatterino Supporter', '2'),
    ]);
    expect(badges.first.badge.mipmap, [
      'https://fourtf.com/chatterino/badges/dev.png',
      'https://fourtf.com/chatterino/badges/dev2x.png',
      'https://fourtf.com/chatterino/badges/dev3x.png',
    ]);
    expect(badges.last.badge.mipmap, ['https://fourtf.com/chatterino/badges/supporter.png']);
    expect(badges.every((b) => b.badge.source == chatterino), isTrue);
    expect(chatterino.name, 'Chatterino');
  });

  test('has no global, channel or user badges of its own', () async {
    final chatterino = source(response);
    expect(await chatterino.globalBadges(), isEmpty);
    expect(await chatterino.channelBadges('1'), isEmpty);
    expect(await chatterino.userBadges('1'), isEmpty);
  });

  test('a listed user gets the badges through UserBadges', () async {
    final userBadges = UserBadges()..change(await source(response).globalUserBadges());

    expect(userBadges.badgesOf('1').map((b) => b.name), ['Chatterino Developer']);
    expect(userBadges.badgesOf('2').map((b) => b.name), ['Chatterino Developer', 'Chatterino Supporter']);
    expect(userBadges.badgesOf('3'), isEmpty);
  });

  group('EmoteBadgeCache', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coldchat_chatterino_source_test');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    test('restores the badges by the source name', () async {
      final chatterino = source(response);
      final badges = await chatterino.globalUserBadges();
      final cache = EmoteBadgeCache(repository: await EmoteBadgeCacheRepository.open(), sources: [chatterino]);
      await cache.saveUserBadges(EmoteBadgeCache.globalUserBadgesKey, badges);
      await Hive.close();
      Hive.init(tempDir.path);

      final reloaded = EmoteBadgeCache(repository: await EmoteBadgeCacheRepository.open(), sources: [chatterino]);
      final loaded = reloaded.loadUserBadges(EmoteBadgeCache.globalUserBadgesKey);

      expect(loaded.map((b) => (b.badge.id, b.badge.name, b.badge.source, b.users.join(','))), [
        ('chatterino-Chatterino Developer', 'Chatterino Developer', chatterino, '1,2'),
        ('chatterino-Chatterino Supporter', 'Chatterino Supporter', chatterino, '2'),
      ]);
      expect(loaded.first.badge.mipmap, badges.first.badge.mipmap);
    });
  });
}
