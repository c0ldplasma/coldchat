// Guards the stored Hive models: data written by an earlier version must keep loading after an update.
//
// test/fixtures/hive_models.hive is a box written by the adapters as they were when it was made, with one instance of
// every stored model. The test opens a copy of it and checks every field. If it fails after a model change, a
// @HiveType typeId or @HiveField number was changed or reused: revert that instead of updating the fixture.
//
// Only after adding a model or a field on purpose, regenerate the fixture (and add the new values below):
//
//   UPDATE_HIVE_FIXTURE=1 flutter test test/data/hive_storage_test.dart
//
// A normal run never writes it.

import 'dart:io';

import 'package:coldchat/data/custom_command.dart';
import 'package:coldchat/data/filesharing/uploaded_media.dart';
import 'package:coldchat/data/message_trigger.dart';
import 'package:coldchat/data/settings/application_appearance.dart';
import 'package:coldchat/data/settings/blocked_message.dart';
import 'package:coldchat/data/settings/blocked_user.dart';
import 'package:coldchat/data/settings/chat_settings.dart';
import 'package:coldchat/data/settings/mention_message.dart';
import 'package:coldchat/data/settings/mention_user.dart';
import 'package:coldchat/data/settings/message_appearance.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch/user_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/data/user_trigger.dart';
import 'package:coldchat/data/webview/cookie_data.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

const boxName = 'hive_models';
final fixture = File('test/fixtures/$boxName.hive');

TokenData tokenData() => TokenData(
  clientId: 'client-id-1',
  login: 'ronni',
  scopes: ['chat:read', 'user:manage:whispers'],
  userId: '1337',
  expiresAt: DateTime.utc(2027, 3, 4, 5, 6, 7),
  accessToken: 'access-token-1',
);

UserData userData() => UserData(
  displayName: 'Ronni',
  avatarUrl: 'https://example.com/avatar.png',
  offlineUrl: 'https://example.com/offline.png',
);

/// One instance of every stored model, each field set to a value that differs from its default.
Map<String, Object> models() => {
  'TwitchAccount': TwitchAccount(tokenData: tokenData(), userData: userData(), cookies: 'cookie=1'),
  'TokenData': tokenData(),
  'UserData': userData(),
  'CookieData': CookieData(
    name: 'session',
    value: 'abc123',
    expires: DateTime.utc(2028, 1, 2, 3, 4, 5),
    maxAge: 3600,
    domain: '.twitch.tv',
    path: '/chat',
    secure: true,
    httpOnly: true,
  ),
  'UploadedMedia': UploadedMedia(
    url: 'https://example.com/upload.png',
    deletionUrl: 'https://example.com/delete/1',
    time: DateTime.utc(2026, 5, 6, 7, 8, 9),
  ),
  'MessageAppearance': MessageAppearance()
    ..timestamps = false
    ..compact = true
    ..imageEmbeds = false
    ..channelsEmbeds = true
    ..fileEmbeds = false
    ..scale = 1.25
    ..badges = false,
  'ApplicationAppearance': ApplicationAppearance()
    ..compact = true
    ..themeMode = 'light'
    ..highContrast = true
    ..oledBlack = true,
  'BlockedMessage': BlockedMessage(pattern: 'spam.*', regex: true, caseSensitive: true),
  'BlockedUser': BlockedUser(login: 'spammer', id: '666'),
  'MentionMessage': MentionMessage(pattern: 'ronni', notify: true, enableRegex: true, caseSensitive: true),
  'MentionUser': MentionUser(login: 'friend', id: '42'),
  'CustomCommand': CustomCommand(trigger: '/hi', command: 'Hello chat!'),
  'MessageTrigger': MessageTrigger(
    type: MessageTriggerType.block.index,
    pattern: 'bad word',
    enableRegex: true,
    caseSensitive: true,
    showInMentions: false,
    sendNotification: false,
    playSound: false,
  ),
  'UserTrigger': UserTrigger(
    type: UserTriggerType.block.index,
    login: 'troll',
    enableRegex: true,
    caseSensitive: true,
    showInMentions: false,
    sendNotification: false,
    playSound: false,
  ),
  'ChatSettings': ChatSettings()
    ..userAutocompletionWithAt = true
    ..emoteAutocompletionWithColon = true
    ..showLinkImages = true,
};

void expectTokenData(TokenData data) {
  expect(data.clientId, 'client-id-1');
  expect(data.login, 'ronni');
  expect(data.scopes, ['chat:read', 'user:manage:whispers']);
  expect(data.userId, '1337');
  expect(data.expiresAt, DateTime.utc(2027, 3, 4, 5, 6, 7));
  expect(data.accessToken, 'access-token-1');
}

void expectUserData(UserData data) {
  expect(data.displayName, 'Ronni');
  expect(data.avatarUrl, 'https://example.com/avatar.png');
  expect(data.offlineUrl, 'https://example.com/offline.png');
}

void main() {
  late Directory tempDir;

  setUpAll(Hive.registerAdapters);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_hive_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'writes the fixture',
    () async {
      final box = await Hive.openBox<dynamic>(boxName);
      await box.putAll(models());
      await box.close();
      File('${tempDir.path}/$boxName.hive').copySync(fixture.path);
    },
    skip: Platform.environment['UPDATE_HIVE_FIXTURE'] == '1' ? false : 'set UPDATE_HIVE_FIXTURE=1 to regenerate',
  );

  test('the fixture box reads back every field of every model', () async {
    fixture.copySync('${tempDir.path}/$boxName.hive');
    final box = await Hive.openBox<dynamic>(boxName);

    expect(box.keys.toSet(), models().keys.toSet());

    final account = box.get('TwitchAccount') as TwitchAccount;
    expectTokenData(account.tokenData);
    expectUserData(account.userData!);
    expect(account.cookies, 'cookie=1');

    expectTokenData(box.get('TokenData') as TokenData);
    expectUserData(box.get('UserData') as UserData);

    final cookie = box.get('CookieData') as CookieData;
    expect(cookie.name, 'session');
    expect(cookie.value, 'abc123');
    expect(cookie.expires, DateTime.utc(2028, 1, 2, 3, 4, 5));
    expect(cookie.maxAge, 3600);
    expect(cookie.domain, '.twitch.tv');
    expect(cookie.path, '/chat');
    expect(cookie.secure, isTrue);
    expect(cookie.httpOnly, isTrue);

    final media = box.get('UploadedMedia') as UploadedMedia;
    expect(media.url, 'https://example.com/upload.png');
    expect(media.deletionUrl, 'https://example.com/delete/1');
    expect(media.time, DateTime.utc(2026, 5, 6, 7, 8, 9));

    final messageAppearance = box.get('MessageAppearance') as MessageAppearance;
    expect(messageAppearance.timestamps, isFalse);
    expect(messageAppearance.compact, isTrue);
    expect(messageAppearance.imageEmbeds, isFalse);
    expect(messageAppearance.channelsEmbeds, isTrue);
    expect(messageAppearance.fileEmbeds, isFalse);
    expect(messageAppearance.scale, 1.25);
    expect(messageAppearance.badges, isFalse);

    final appAppearance = box.get('ApplicationAppearance') as ApplicationAppearance;
    expect(appAppearance.compact, isTrue);
    expect(appAppearance.themeMode, 'light');
    expect(appAppearance.highContrast, isTrue);
    expect(appAppearance.oledBlack, isTrue);

    final blockedMessage = box.get('BlockedMessage') as BlockedMessage;
    expect(blockedMessage.pattern, 'spam.*');
    expect(blockedMessage.regex, isTrue);
    expect(blockedMessage.caseSensitive, isTrue);

    final blockedUser = box.get('BlockedUser') as BlockedUser;
    expect(blockedUser.login, 'spammer');
    expect(blockedUser.id, '666');

    final mentionMessage = box.get('MentionMessage') as MentionMessage;
    expect(mentionMessage.pattern, 'ronni');
    expect(mentionMessage.notify, isTrue);
    expect(mentionMessage.enableRegex, isTrue);
    expect(mentionMessage.caseSensitive, isTrue);

    final mentionUser = box.get('MentionUser') as MentionUser;
    expect(mentionUser.login, 'friend');
    expect(mentionUser.id, '42');

    final command = box.get('CustomCommand') as CustomCommand;
    expect(command.trigger, '/hi');
    expect(command.command, 'Hello chat!');

    final messageTrigger = box.get('MessageTrigger') as MessageTrigger;
    expect(messageTrigger.type, MessageTriggerType.block.index);
    expect(messageTrigger.pattern, 'bad word');
    expect(messageTrigger.enableRegex, isTrue);
    expect(messageTrigger.caseSensitive, isTrue);
    expect(messageTrigger.showInMentions, isFalse);
    expect(messageTrigger.sendNotification, isFalse);
    expect(messageTrigger.playSound, isFalse);

    final userTrigger = box.get('UserTrigger') as UserTrigger;
    expect(userTrigger.type, UserTriggerType.block.index);
    expect(userTrigger.login, 'troll');
    expect(userTrigger.enableRegex, isTrue);
    expect(userTrigger.caseSensitive, isTrue);
    expect(userTrigger.showInMentions, isFalse);
    expect(userTrigger.sendNotification, isFalse);
    expect(userTrigger.playSound, isFalse);

    final chatSettings = box.get('ChatSettings') as ChatSettings;
    expect(chatSettings.userAutocompletionWithAt, isTrue);
    expect(chatSettings.emoteAutocompletionWithColon, isTrue);
    expect(chatSettings.showLinkImages, isTrue);
  });

  test('adapter type ids stay the same', () {
    expect(
      {
        'TwitchAccount': TwitchAccountAdapter().typeId,
        'TokenData': TokenDataAdapter().typeId,
        'UserData': UserDataAdapter().typeId,
        'CookieData': CookieDataAdapter().typeId,
        'UploadedMedia': UploadedMediaAdapter().typeId,
        'MessageAppearance': MessageAppearanceAdapter().typeId,
        'ApplicationAppearance': ApplicationAppearanceAdapter().typeId,
        'BlockedMessage': BlockedMessageAdapter().typeId,
        'BlockedUser': BlockedUserAdapter().typeId,
        'MentionMessage': MentionMessageAdapter().typeId,
        'MentionUser': MentionUserAdapter().typeId,
        'CustomCommand': CustomCommandAdapter().typeId,
        'MessageTrigger': MessageTriggerAdapter().typeId,
        'UserTrigger': UserTriggerAdapter().typeId,
        'ChatSettings': ChatSettingsAdapter().typeId,
      },
      {
        'TwitchAccount': 1,
        'TokenData': 2,
        'UserData': 3,
        'CookieData': 4,
        'UploadedMedia': 5,
        'MessageAppearance': 6,
        'ApplicationAppearance': 7,
        'BlockedMessage': 8,
        'BlockedUser': 9,
        'MentionMessage': 10,
        'MentionUser': 11,
        'CustomCommand': 12,
        'MessageTrigger': 13,
        'UserTrigger': 14,
        'ChatSettings': 15,
      },
    );
  });
}
