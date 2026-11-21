import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../tools/account_swipe.dart';
import '../twitch/token_data.dart';
import '../twitch_account.dart';
import 'box_changes.dart';

/// What [AccountRepository.setActive] connects or disconnects: the chat client, or a fake in tests.
abstract interface class AccountConnector {
  /// Connects as [twitchAccount], replacing the account connected before.
  Future<void> connectAs(TwitchAccount twitchAccount);

  /// Logs out: closes the connections until [connectAs] is called again.
  void disconnect();
}

/// The saved Twitch logins (box `TwitchAccounts`, keyed by `userId@clientId`, see [TokenData.hash]) and which one is
/// active (box `AccountSettings`, key `activeTwitchAccount`, holding that hash).
class AccountRepository {
  static const String accountsBoxName = 'TwitchAccounts';
  static const String accountSettingsBoxName = 'AccountSettings';
  static const String activeAccountKey = 'activeTwitchAccount';

  final Box<dynamic> _accounts;
  final Box<dynamic> _accountSettings;

  /// Takes the open `TwitchAccounts` and `AccountSettings` boxes; [open] opens them.
  AccountRepository(this._accounts, this._accountSettings);

  /// The folder in the app's documents folder that holds the `TwitchAccounts` box on iOS. `ios/Runner/AppDelegate.swift`
  /// creates it at launch and excludes it from iCloud and computer backups, which keeps the access tokens out of
  /// them, like `android/app/src/main/res/xml/backup_rules.xml` does on Android. The flag is on the folder rather than
  /// the box file because Hive replaces the file when it compacts it, and a new file wouldn't keep the flag.
  static const String iosLoginsFolder = 'Logins';

  /// Opens the boxes. [accountsPath] is the folder of the `TwitchAccounts` box, null for Hive's home folder; logins
  /// that earlier versions stored in the home folder are moved there first (see [moveLogins]).
  static Future<AccountRepository> open({String? accountsPath}) async {
    if (accountsPath != null) await moveLogins(to: accountsPath);
    final (accounts, accountSettings) = await (
      Hive.openBox<dynamic>(accountsBoxName, path: accountsPath),
      Hive.openBox<dynamic>(accountSettingsBoxName),
    ).wait;
    return AccountRepository(accounts, accountSettings);
  }

  /// Moves the `TwitchAccounts` box from Hive's home folder to the folder [to], if the home folder has one. Neither
  /// box may be open.
  ///
  /// The new box is written and closed before the old files are deleted, so an interrupted move is simply repeated at
  /// the next start, and nobody is logged out. Only the current accounts are copied: Hive appends to its files, so the
  /// old file can still hold the tokens of removed accounts. The `cookies` of an account (written by Chatsen's web-view
  /// login and unused since) are dropped.
  static Future<void> moveLogins({required String to}) async {
    if (!await Hive.boxExists(accountsBoxName)) return;
    final oldBox = await Hive.openBox<dynamic>(accountsBoxName);
    final copies = {
      for (final MapEntry(:key, :value) in oldBox.toMap().entries)
        if (value is TwitchAccount)
          key: TwitchAccount(tokenData: value.tokenData, userData: value.userData, cookies: null),
    };
    await oldBox.close();

    final newBox = await Hive.openBox<dynamic>(accountsBoxName, path: to);
    await newBox.putAll(copies);
    await newBox.close();

    await Hive.deleteBoxFromDisk(accountsBoxName);
  }

  /// Every saved account, in the order they were stored.
  List<TwitchAccount> get accounts => _accounts.values.whereType<TwitchAccount>().toList();

  /// The [TokenData.hash] of the active account, or null when logged out.
  String? get activeHash {
    final hash = _accountSettings.get(activeAccountKey);
    return hash is String ? hash : null;
  }

  /// The active account, or null when logged out (or the stored hash matches no saved account).
  TwitchAccount? get active {
    final hash = activeHash;
    if (hash == null) return null;
    return accounts.firstWhereOrNull((account) => account.tokenData.hash == hash);
  }

  /// The saved accounts other than the active one.
  List<TwitchAccount> get inactive => [
    for (final account in accounts)
      if (account.tokenData.hash != activeHash) account,
  ];

  bool isActive(TwitchAccount account) => account.tokenData.hash == activeHash;

  /// Fires when an account is added, changed or removed, or another account becomes active.
  late final Listenable changes = Listenable.merge([BoxChanges(_accounts), BoxChanges(_accountSettings)]);

  /// Fires when another account becomes active or the user logs out.
  late final Listenable activeChanges = BoxChanges(_accountSettings, keys: const [activeAccountKey]);

  /// Makes [account] the active account and connects [client] as it, or logs out when [account] is null.
  ///
  /// Always go through this instead of writing the active account directly: the client doesn't listen to the
  /// storage, so it would keep chatting as the previous account.
  Future<void> setActive(AccountConnector client, TwitchAccount? account) async {
    if (account == null) {
      client.disconnect();
      await _accountSettings.delete(activeAccountKey);
    } else {
      unawaited(client.connectAs(account));
      await _accountSettings.put(activeAccountKey, account.tokenData.hash);
    }
  }

  /// Stores a fresh login, replacing older entries of the same user (see [keysReplacedByLogin]). Doesn't make it
  /// active: call [setActive] for that.
  Future<void> saveLogin(TwitchAccount account) async {
    await _accounts.deleteAll(keysReplacedByLogin(_accounts.toMap(), account.tokenData));
    await _accounts.put(account.tokenData.hash, account);
  }

  /// Writes changes made to a saved [account] (e.g. a refreshed expiry). Throws when it isn't saved.
  Future<void> update(TwitchAccount account) => account.save();

  /// Removes [account]. When it was the active one, switches [client] to the first other saved account, or logs out
  /// when it was the last one.
  Future<void> remove(AccountConnector client, TwitchAccount account) async {
    if (isActive(account)) await setActive(client, accountAfterRemoving(accounts, account));
    await account.delete();
  }

  /// The saved account a vertical [swipe] on the avatar switches to, or null when there's nothing to switch to.
  TwitchAccount? swipeTarget(AccountSwipe swipe) {
    final hash = activeHash;
    final index = swipedAccountIndex(
      current: _accounts.keys.toList().indexOf(hash),
      count: _accounts.length,
      swipe: swipe,
    );
    if (index == null) return null;
    final next = _accounts.getAt(index);
    if (next is! TwitchAccount || next.tokenData.hash == hash) return null;
    return next;
  }
}

/// The account to switch to when the active account [removed] is removed: the first other one of [accounts], or
/// null to log out when it was the last one.
TwitchAccount? accountAfterRemoving(Iterable<TwitchAccount> accounts, TwitchAccount removed) =>
    accounts.where((account) => account.tokenData.hash != removed.tokenData.hash).firstOrNull;

/// The keys of the stored accounts that a new login with [tokenData] replaces: every other entry of the same user.
///
/// Accounts are keyed by userId@clientId. Signing in again as the same user replaces the stale entry (and its dead
/// expiresAt), also one stored under a different client id, such as a login from before ColdChat had its own Twitch
/// app.
List<dynamic> keysReplacedByLogin(Map<dynamic, dynamic> storedAccounts, TokenData tokenData) => [
  for (final entry in storedAccounts.entries)
    if (entry.key != tokenData.hash &&
        entry.value is TwitchAccount &&
        (entry.value as TwitchAccount).tokenData.userId == tokenData.userId)
      entry.key,
];
