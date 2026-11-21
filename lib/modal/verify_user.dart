import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/twitch/twitch.dart';
import '../data/repositories/account_repository.dart';
import '../data/twitch/token_data.dart';
import '../data/twitch/user_data.dart';
import '../data/twitch_account.dart';
import '../l10n/app_localizations.dart';
import '../tmi/client/client.dart';

class VerifyUserModal extends StatefulWidget {
  final TokenData tokenData;
  final String? cookies;

  const VerifyUserModal({
    super.key,
    required this.tokenData,
    required this.cookies,
  });

  @override
  State<VerifyUserModal> createState() => _VerifyUserModalState();
}

class _VerifyUserModalState extends State<VerifyUserModal> {
  late Future<UserData> future;

  @override
  void initState() {
    final accounts = context.read<AccountRepository>();
    future = Twitch.userData(widget.tokenData);
    unawaited(
      future.then(
        (value) async {
          final twitchAccount = TwitchAccount(
            tokenData: widget.tokenData,
            userData: value,
            cookies: widget.cookies,
          );

          await accounts.saveLogin(twitchAccount);

          // The account just signed in to becomes the active one: adding an account, or signing in again as one, is
          // a deliberate choice to use it now. This also makes a fresh token take effect immediately instead of the
          // connection sitting in ConnectionInvalidCredentials with the old one.
          if (mounted) await accounts.setActive(context.read<Client>(), twitchAccount);

          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16.0),
    child: FutureBuilder<UserData>(
      future: future,
      builder: (context, snapshot) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (snapshot.hasData) ...[
              Icon(
                Icons.check,
                size: 64.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              // TODO: Display both background and avatar
              const SizedBox(height: 16.0),
              Text(AppLocalizations.of(context).verifiedUserData),
              Text(AppLocalizations.of(context).loggedInAs(snapshot.data!.displayName)),
            ],
            if (snapshot.hasError) ...[
              Icon(
                Icons.block,
                size: 64.0,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16.0),
              Text(AppLocalizations.of(context).anErrorHasOccuredWhenVerifyingUserData),
              Text('${snapshot.error}'),
            ],
            if (!snapshot.hasData && !snapshot.hasError) ...[
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: 16.0),
              Text(AppLocalizations.of(context).verifyingUserData),
            ],
          ],
        );
      },
    ),
  );
}
