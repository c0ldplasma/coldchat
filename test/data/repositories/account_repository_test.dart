import 'dart:convert';
import 'dart:io';

import 'package:coldchat/data/repositories/account_repository.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/tools/account_swipe.dart';
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

/// Records what [AccountRepository.setActive] asks the chat client to do.
class _FakeConnector implements AccountConnector {
  final List<String> calls = [];

  @override
  Future<void> connectAs(TwitchAccount twitchAccount) async => calls.add('connectAs ${twitchAccount.tokenData.hash}');

  @override
  void disconnect() => calls.add('disconnect');
}

void main() {
  setUpAll(Hive.registerAdapters);

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

  group('AccountRepository', () {
    late Directory tempDir;
    late AccountRepository repository;
    late Box<dynamic> accounts;
    late Box<dynamic> accountSettings;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('coldchat_account_repository_test');
      Hive.init(tempDir.path);
      repository = await AccountRepository.open();
      accounts = Hive.box<dynamic>('TwitchAccounts');
      accountSettings = Hive.box<dynamic>('AccountSettings');
    });

    tearDown(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    Future<List<TwitchAccount>> store(List<String> userIds) async {
      final stored = [for (final id in userIds) _account(id)];
      for (final account in stored) {
        await accounts.put(account.tokenData.hash, account);
      }
      return stored;
    }

    test('uses the existing boxes and keys', () {
      expect(AccountRepository.accountsBoxName, 'TwitchAccounts');
      expect(AccountRepository.accountSettingsBoxName, 'AccountSettings');
      expect(AccountRepository.activeAccountKey, 'activeTwitchAccount');
    });

    test('reads the active account from data stored the way earlier versions did', () async {
      final [a, b] = await store(['1', '2']);
      await accountSettings.put('activeTwitchAccount', '2@coldchat');

      expect(repository.accounts, [a, b]);
      expect(repository.activeHash, '2@coldchat');
      expect(repository.active, same(b));
      expect(repository.inactive, [a]);
      expect(repository.isActive(b), isTrue);
      expect(repository.isActive(a), isFalse);
    });

    test('logged out without an active account, or one that is not saved anymore', () async {
      await store(['1']);
      expect(repository.active, isNull);
      expect(repository.inactive, hasLength(1));

      await accountSettings.put('activeTwitchAccount', '9@coldchat');
      expect(repository.active, isNull);

      await accountSettings.put('activeTwitchAccount', 42);
      expect(repository.activeHash, isNull);
    });

    test('setActive connects as the account and stores it as the active one', () async {
      final connector = _FakeConnector();
      final account = _account('1');

      await repository.setActive(connector, account);

      expect(connector.calls, ['connectAs 1@coldchat']);
      expect(accountSettings.get('activeTwitchAccount'), '1@coldchat');
    });

    test('switching replaces the active account and connects as the new one', () async {
      final connector = _FakeConnector();

      await repository.setActive(connector, _account('1'));
      await repository.setActive(connector, _account('2'));

      expect(connector.calls, ['connectAs 1@coldchat', 'connectAs 2@coldchat']);
      expect(accountSettings.get('activeTwitchAccount'), '2@coldchat');
    });

    test('setActive(null) logs out: disconnects and forgets the active account', () async {
      final connector = _FakeConnector();
      await repository.setActive(connector, _account('1'));

      await repository.setActive(connector, null);

      expect(connector.calls, ['connectAs 1@coldchat', 'disconnect']);
      expect(accountSettings.containsKey('activeTwitchAccount'), isFalse);
    });

    test('saveLogin stores the account under its hash and replaces older logins of the same user', () async {
      final old = _account('1', clientId: 'chatsen');
      await accounts.put(old.tokenData.hash, old);
      await store(['2']);
      final login = _account('1');

      await repository.saveLogin(login);

      expect(accounts.keys.toSet(), {'2@coldchat', '1@coldchat'});
      expect(accounts.get('1@coldchat'), same(login));
      // Saving doesn't make it active.
      expect(repository.active, isNull);
    });

    test('removing the active account switches to the first remaining one', () async {
      final [a, b, c] = await store(['1', '2', '3']);
      final connector = _FakeConnector();
      await repository.setActive(connector, a);

      await repository.remove(connector, a);

      expect(repository.accounts, [b, c]);
      expect(repository.active, same(b));
      expect(connector.calls.last, 'connectAs 2@coldchat');
    });

    test('removing the last account logs out', () async {
      final [a] = await store(['1']);
      final connector = _FakeConnector();
      await repository.setActive(connector, a);

      await repository.remove(connector, a);

      expect(repository.accounts, isEmpty);
      expect(repository.active, isNull);
      expect(connector.calls.last, 'disconnect');
      expect(accountSettings.containsKey('activeTwitchAccount'), isFalse);
    });

    test('removing an inactive account keeps the active one connected', () async {
      final [a, b] = await store(['1', '2']);
      final connector = _FakeConnector();
      await repository.setActive(connector, a);

      await repository.remove(connector, b);

      expect(repository.accounts, [a]);
      expect(repository.active, same(a));
      expect(connector.calls, ['connectAs 1@coldchat']);
    });

    test('update writes changes of a saved account', () async {
      final [a] = await store(['1']);
      a.tokenData.scopes = ['user:manage:whispers'];

      await repository.update(a);
      await Hive.close();
      Hive.init(tempDir.path);
      repository = await AccountRepository.open();

      expect(repository.accounts.single.tokenData.scopes, ['user:manage:whispers']);
    });

    test('swipeTarget moves through the saved accounts and wraps around', () async {
      final [a, b, c] = await store(['1', '2', '3']);
      final connector = _FakeConnector();

      // Without an active account a swipe up starts at the first one, a swipe down at the last one.
      expect(repository.swipeTarget(AccountSwipe.next), same(a));
      expect(repository.swipeTarget(AccountSwipe.previous), same(c));

      await repository.setActive(connector, b);
      expect(repository.swipeTarget(AccountSwipe.next), same(c));
      expect(repository.swipeTarget(AccountSwipe.previous), same(a));

      await repository.setActive(connector, c);
      expect(repository.swipeTarget(AccountSwipe.next), same(a));
    });

    test('swipeTarget is null with a single account that is already active', () async {
      final [a] = await store(['1']);
      await repository.setActive(_FakeConnector(), a);

      expect(repository.swipeTarget(AccountSwipe.next), isNull);
    });

    test('changes fires for saved accounts and the active one; activeChanges only for the active one', () async {
      var changes = 0;
      var activeChanges = 0;
      repository.changes.addListener(() => changes++);
      repository.activeChanges.addListener(() => activeChanges++);

      final [a] = await store(['1']);
      await pumpEventQueue();
      expect((changes, activeChanges), (1, 0));

      await repository.setActive(_FakeConnector(), a);
      await pumpEventQueue();
      expect((changes, activeChanges), (2, 1));
    });

    test('reads the account in the stored-models fixture', () async {
      await Hive.close();
      File('test/fixtures/hive_models.hive').copySync('${tempDir.path}/twitchaccounts.hive');
      Hive.init(tempDir.path);
      repository = await AccountRepository.open();

      // The fixture holds one of every model; only the account is one.
      final account = repository.accounts.single;
      expect(account.tokenData.hash, '1337@client-id-1');
      expect(account.userData?.displayName, 'Ronni');
    });
  });

  group('AccountRepository.open with accountsPath', () {
    late Directory tempDir;
    late String loginsPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('coldchat_account_move_test');
      loginsPath = '${tempDir.path}/Logins';
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    bool hasBoxFiles(String folder) => ['hive', 'hivec', 'lock'].any(
      (extension) => File('$folder/twitchaccounts.$extension').existsSync(),
    );

    /// Stores [accounts] the way earlier versions did: in the home folder, the active one in AccountSettings.
    Future<void> storeInHomeFolder(List<TwitchAccount> accounts, {String? active}) async {
      final box = await Hive.openBox<dynamic>('TwitchAccounts');
      for (final account in accounts) {
        await box.put(account.tokenData.hash, account);
      }
      await box.close();
      final settings = await Hive.openBox<dynamic>('AccountSettings');
      if (active != null) await settings.put('activeTwitchAccount', active);
      await settings.close();
    }

    test('moves the logins out of the home folder without logging anyone out', () async {
      final withCookies = _account('2')..cookies = 'auth-token=secret';
      await storeInHomeFolder([_account('1'), withCookies], active: '2@coldchat');

      final repository = await AccountRepository.open(accountsPath: loginsPath);

      expect(repository.accounts.map((account) => account.tokenData.hash), ['1@coldchat', '2@coldchat']);
      expect(repository.active?.tokenData.accessToken, 'token-2-coldchat');
      expect(repository.active?.cookies, isNull);
      expect(hasBoxFiles(tempDir.path), isFalse);
      expect(File('$loginsPath/twitchaccounts.hive').existsSync(), isTrue);
      expect(File('$loginsPath/twitchaccounts.hive').readAsStringSync(encoding: latin1), isNot(contains('secret')));
    });

    test('leaves out the tokens of removed accounts that the old file still held', () async {
      final box = await Hive.openBox<dynamic>('TwitchAccounts');
      await box.put('1@coldchat', _account('1'));
      await box.put('9@coldchat', _account('9'));
      await box.delete('9@coldchat');
      await box.close();
      expect(File('${tempDir.path}/twitchaccounts.hive').readAsStringSync(encoding: latin1), contains('token-9'));

      final repository = await AccountRepository.open(accountsPath: loginsPath);

      expect(repository.accounts.map((account) => account.tokenData.hash), ['1@coldchat']);
      expect(File('$loginsPath/twitchaccounts.hive').readAsStringSync(encoding: latin1), isNot(contains('token-9')));
    });

    test('keeps using the moved box at the next start', () async {
      await storeInHomeFolder([_account('1')]);
      final first = await AccountRepository.open(accountsPath: loginsPath);
      await first.saveLogin(_account('2'));
      await Hive.close();

      final repository = await AccountRepository.open(accountsPath: loginsPath);

      expect(repository.accounts.map((account) => account.tokenData.hash), ['1@coldchat', '2@coldchat']);
      expect(hasBoxFiles(tempDir.path), isFalse);
    });

    test('finishes a move that was interrupted before the old box was deleted', () async {
      await storeInHomeFolder([_account('1')]);
      final copy = await Hive.openBox<dynamic>('TwitchAccounts', path: loginsPath);
      await copy.put('1@coldchat', _account('1'));
      await copy.close();

      final repository = await AccountRepository.open(accountsPath: loginsPath);

      expect(repository.accounts.map((account) => account.tokenData.hash), ['1@coldchat']);
      expect(hasBoxFiles(tempDir.path), isFalse);
    });

    test('starts without logins on a fresh install', () async {
      final repository = await AccountRepository.open(accountsPath: loginsPath);

      expect(repository.accounts, isEmpty);
      expect(hasBoxFiles(tempDir.path), isFalse);
    });

    test('moves the box in the stored-models fixture', () async {
      File('test/fixtures/hive_models.hive').copySync('${tempDir.path}/twitchaccounts.hive');

      final repository = await AccountRepository.open(accountsPath: loginsPath);

      expect(repository.accounts.single.tokenData.hash, '1337@client-id-1');
      expect(repository.accounts.single.userData?.displayName, 'Ronni');
      expect(hasBoxFiles(tempDir.path), isFalse);
    });
  });
}
