import 'dart:io';

import 'package:coldchat/data/repositories/whisper_repository.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/tmi/whispers/whispers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../client/fake_client.dart';

TwitchAccount _account(String userId) => TwitchAccount(
  tokenData: TokenData(
    clientId: 'coldchat',
    login: 'user$userId',
    scopes: const [Whispers.scope],
    userId: userId,
    expiresAt: null,
    accessToken: 'token-$userId',
  ),
  userData: null,
  cookies: null,
);

Map<String, Object?> _stored(String login, {required bool open, required int openedAt}) => {
  'login': login,
  'name': login.toUpperCase(),
  'open': open,
  'unread': false,
  'openedAt': openedAt,
  'lines': <String>[],
};

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late Whispers whispers;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('coldchat_whispers_storage_test');
    Hive.init(tempDir.path);
    whispers = Whispers(FakeClient(), storage: await WhisperRepository.open());
    box = Hive.box<dynamic>('Whispers');
  });

  tearDown(() async {
    for (final conversation in whispers.state) {
      await conversation.close();
    }
    await whispers.close();
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test("an account's open conversations come back as tabs, in the order they were opened", () async {
    await box.putAll({
      '1/20': _stored('second', open: true, openedAt: 200),
      '1/10': _stored('first', open: true, openedAt: 100),
      '1/30': _stored('closed', open: false, openedAt: 50),
      '2/40': _stored('otheraccount', open: true, openedAt: 10),
    });

    whispers.setAccount(_account('1'));

    expect([for (final c in whispers.state) c.partnerLogin], ['first', 'second']);
    expect([for (final c in whispers.state) c.partnerId], ['10', '20']);
  });

  test('closing a tab keeps the conversation stored, deleting it removes it', () async {
    await box.putAll({
      '1/10': _stored('first', open: true, openedAt: 100),
      '1/20': _stored('second', open: true, openedAt: 200),
    });
    whispers.setAccount(_account('1'));
    final [first, second] = whispers.state;

    whispers.closeConversation(first);
    whispers.deleteConversation(second);
    await pumpEventQueue();

    expect(whispers.state, isEmpty);
    final stored = box.get('1/10') as Map;
    expect(stored['open'], isFalse);
    expect(stored['login'], 'first');
    expect(box.containsKey('1/20'), isFalse);
  });

  test('marking a conversation read keeps when it was opened', () async {
    await box.put('1/10', {..._stored('first', open: true, openedAt: 100), 'unread': true});
    whispers.setAccount(_account('1'));

    whispers.markRead(whispers.state.single);
    await pumpEventQueue();

    final stored = box.get('1/10') as Map;
    expect(stored['unread'], isFalse);
    expect(stored['openedAt'], 100);
  });
}
