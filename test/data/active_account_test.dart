import 'dart:io';

import 'package:coldchat/data/active_account.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

TwitchAccount _account(String userId, {String clientId = 'coldchat', String? login}) => TwitchAccount(
  tokenData: TokenData(
    clientId: clientId,
    login: login ?? 'user$userId',
    scopes: const [],
    userId: userId,
    expiresAt: null,
    accessToken: 'token-$userId-$clientId',
  ),
  userData: null,
  cookies: null,
);

/// Records what [setActiveAccount] asks the chat client to do.
class _FakeConnector implements AccountConnector {
  final List<String> calls = [];

  @override
  Future<void> connectAs(TwitchAccount twitchAccount) async => calls.add('connectAs ${twitchAccount.tokenData.hash}');

  @override
  void disconnect() => calls.add('disconnect');
}

void main() {
  group('accountAfterRemoving', () {
    test('switches to the first other account', () {
      final a = _account('1');
      final b = _account('2');
      final c = _account('3');

      expect(accountAfterRemoving([a, b, c], a), same(b));
      expect(accountAfterRemoving([a, b, c], b), same(a));
      expect(accountAfterRemoving([a, b, c], c), same(a));
    });

    test('logs out when the removed account was the last one', () {
      final a = _account('1');

      expect(accountAfterRemoving([a], a), isNull);
      expect(accountAfterRemoving([], a), isNull);
    });

    test('compares by userId@clientId, not by object', () {
      final stored = _account('1');
      final sameLogin = _account('1');
      final other = _account('2');

      expect(accountAfterRemoving([stored, other], sameLogin), same(other));
    });
  });

  group('keysReplacedByLogin', () {
    test('replaces an older entry of the same user under another client id', () {
      final old = _account('1', clientId: 'chatsen');
      final login = _account('1');

      expect(
        keysReplacedByLogin({old.tokenData.hash: old, _account('2').tokenData.hash: _account('2')}, login.tokenData),
        ['1@chatsen'],
      );
    });

    test('leaves the entry the login itself is stored under alone, it is overwritten anyway', () {
      final old = _account('1');
      final login = _account('1');

      expect(keysReplacedByLogin({old.tokenData.hash: old}, login.tokenData), isEmpty);
    });

    test('keeps the accounts of other users and entries that are not accounts', () {
      final login = _account('1');

      expect(
        keysReplacedByLogin({
          '2@coldchat': _account('2'),
          '3@coldchat': _account('3'),
          'junk': 'not an account',
        }, login.tokenData),
        isEmpty,
      );
    });

    test('replaces every older entry of the same user', () {
      final login = _account('1');

      expect(
        keysReplacedByLogin({
          '1@chatsen': _account('1', clientId: 'chatsen'),
          '1@other': _account('1', clientId: 'other'),
          '2@coldchat': _account('2'),
        }, login.tokenData),
        ['1@chatsen', '1@other'],
      );
    });
  });

  group('setActiveAccount', () {
    late Directory tempDir;
    late Box<dynamic> accountSettings;

    setUpAll(Hive.registerAdapters);

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('coldchat_active_account_test');
      Hive.init(tempDir.path);
      accountSettings = await Hive.openBox<dynamic>('AccountSettings');
    });

    tearDown(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    test('connects as the account and stores it as the active one', () async {
      final connector = _FakeConnector();
      final account = _account('1');

      await setActiveAccount(connector, account);

      expect(connector.calls, ['connectAs 1@coldchat']);
      expect(accountSettings.get('activeTwitchAccount'), '1@coldchat');
    });

    test('switching replaces the active account and connects as the new one', () async {
      final connector = _FakeConnector();

      await setActiveAccount(connector, _account('1'));
      await setActiveAccount(connector, _account('2'));

      expect(connector.calls, ['connectAs 1@coldchat', 'connectAs 2@coldchat']);
      expect(accountSettings.get('activeTwitchAccount'), '2@coldchat');
    });

    test('null logs out: disconnects and forgets the active account', () async {
      final connector = _FakeConnector();
      await setActiveAccount(connector, _account('1'));

      await setActiveAccount(connector, null);

      expect(connector.calls, ['connectAs 1@coldchat', 'disconnect']);
      expect(accountSettings.containsKey('activeTwitchAccount'), isFalse);
    });
  });
}
