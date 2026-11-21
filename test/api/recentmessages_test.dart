import 'dart:convert';
import 'dart:io';

import 'package:coldchat/api/recentmessages/recentmessages.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;
  late MockClient client;

  setUp(() {
    requests = [];
    client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        json.encode({
          'messages': ['@id=1 :a!a@a.tmi.twitch.tv PRIVMSG #forsen :hi'],
        }),
        200,
      );
    });
  });

  test('fetches the channel history while chat history is on', () async {
    final recentMessages = RecentMessages(enabled: () => true, client: client);

    final lines = await recentMessages.channel('forsen');

    expect(lines, ['@id=1 :a!a@a.tmi.twitch.tv PRIVMSG #forsen :hi']);
    expect(requests.single.url, Uri.parse('https://recent-messages.robotty.de/api/v2/recent-messages/forsen'));
  });

  test('makes no request at all while chat history is off', () async {
    final recentMessages = RecentMessages(enabled: () => false, client: client);

    expect(await recentMessages.channel('forsen'), isNull);
    expect(requests, isEmpty);
  });

  group('follows Settings → Chat history', () {
    late Directory tempDir;
    late SettingsRepository settings;
    late RecentMessages recentMessages;

    setUpAll(Hive.registerAdapters);

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('coldchat_recentmessages_test');
      Hive.init(tempDir.path);
      settings = await SettingsRepository.open();
      recentMessages = RecentMessages(enabled: () => settings.chatHistory, client: client);
    });

    tearDown(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    test('on for a fresh install that never touched the switch', () async {
      expect(await recentMessages.channel('forsen'), isNotNull);
      expect(requests, hasLength(1));
    });

    test('switching takes effect with the next fetch', () async {
      await settings.setChatHistory(false);
      expect(await recentMessages.channel('forsen'), isNull);
      expect(requests, isEmpty);

      await settings.setChatHistory(true);
      expect(await recentMessages.channel('forsen'), isNotNull);
      expect(requests, hasLength(1));
    });
  });
}
