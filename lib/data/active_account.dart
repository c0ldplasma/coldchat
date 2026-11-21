import 'dart:async';

import 'package:hive_ce/hive_ce.dart';

import '../tmi/client/client.dart';
import 'twitch_account.dart';

/// Makes [account] the active account and connects [client] as it, or logs out when [account] is null.
///
/// Always go through this instead of writing `activeTwitchAccount` to the `AccountSettings` box directly: the client
/// doesn't listen to that box, so it would keep chatting as the previous account.
Future<void> setActiveAccount(Client client, TwitchAccount? account) async {
  final accountSettingsBox = Hive.box<dynamic>('AccountSettings');
  if (account == null) {
    client.disconnect();
    await accountSettingsBox.delete('activeTwitchAccount');
  } else {
    unawaited(client.connectAs(account));
    await accountSettingsBox.put('activeTwitchAccount', account.tokenData.hash);
  }
}
