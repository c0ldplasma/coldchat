import 'dart:async';

import 'package:hive_ce/hive_ce.dart';

import 'twitch/token_data.dart';
import 'twitch_account.dart';

/// What [setActiveAccount] connects or disconnects: the chat client, or a fake in tests.
abstract interface class AccountConnector {
  /// Connects as [twitchAccount], replacing the account connected before.
  Future<void> connectAs(TwitchAccount twitchAccount);

  /// Logs out: closes the connections until [connectAs] is called again.
  void disconnect();
}

/// Makes [account] the active account and connects [client] as it, or logs out when [account] is null.
///
/// Always go through this instead of writing `activeTwitchAccount` to the `AccountSettings` box directly: the client
/// doesn't listen to that box, so it would keep chatting as the previous account.
Future<void> setActiveAccount(AccountConnector client, TwitchAccount? account) async {
  final accountSettingsBox = Hive.box<dynamic>('AccountSettings');
  if (account == null) {
    client.disconnect();
    await accountSettingsBox.delete('activeTwitchAccount');
  } else {
    unawaited(client.connectAs(account));
    await accountSettingsBox.put('activeTwitchAccount', account.tokenData.hash);
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
