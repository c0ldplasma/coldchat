import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/boxlistener.dart';
import '../components/modal.dart';
import '../components/separator.dart';
import '../components/tile.dart';
import '../data/twitch_account.dart';
import '../l10n/app_localizations.dart';
import '../tmi/client/client.dart';
import 'about.dart';
import 'components/modal_header.dart';
import 'login_flow.dart';
import 'settings.dart';
import 'twitch_account.dart';
import 'twitch_token_input.dart';

class ColdChatModal extends StatelessWidget {
  const ColdChatModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BoxListener(
      box: Hive.box<dynamic>('AccountSettings'),
      builder: (context, accountSettingsBox) {
        return BoxListener(
          box: Hive.box<dynamic>('TwitchAccounts'),
          builder: (BuildContext context, Box<dynamic> twitchAccountsBox) {
            final activeTwitchAccount = twitchAccountsBox.values.firstWhere(
              (element) => accountSettingsBox.get('activeTwitchAccount') == (element as TwitchAccount).tokenData.hash,
              orElse: () => null,
            ) as TwitchAccount?;
            return ListView(
              shrinkWrap: true,
              children: [
                ModalHeader(
                  title: AppLocalizations.of(context).appName,
                  trailing: Tooltip(
                    message: AppLocalizations.of(context).settings,
                    child: InkWell(
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Modal.show(
                          context: context,
                          child: const SettingsModal(),
                        );
                      },
                      borderRadius: BorderRadius.circular(24.0),
                      child: const SizedBox(
                        width: 40.0,
                        height: 40.0,
                        child: Icon(Icons.settings_outlined),
                      ),
                    ),
                  ),
                ),
                if (activeTwitchAccount != null) ...[
                  TwitchAccountButton(
                    active: true,
                    // key: ObjectKey(twitchAccount),
                    twitchAccount: activeTwitchAccount,
                  ),
                  const Separator(),
                ],
                for (var twitchAccount in twitchAccountsBox.values.where(
                  (element) =>
                      accountSettingsBox.get('activeTwitchAccount') != (element as TwitchAccount).tokenData.hash,
                ))
                  TwitchAccountButton(
                    // key: ObjectKey(twitchAccount),
                    twitchAccount: twitchAccount as TwitchAccount,
                  ),
                Tile(
                  onTap: () => showTwitchLogin(context),
                  onLongPress: () {
                    unawaited(
                      Modal.show(
                        context: context,
                        child: const TwitchTokenInputModal(),
                      ),
                    );
                  },
                  prefix: const Icon(Icons.person_add_alt),
                  title: AppLocalizations.of(context).addAnotherAccount,
                ),
                const Separator(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(4.0),
                        onTap: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            AppLocalizations.of(context).privacyPolicy,
                            style: const TextStyle(
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Material(
                          color: Theme.of(context).colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(4.0),
                          child: const SizedBox(
                            height: 4.0,
                            width: 4.0,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(4.0),
                        onTap: () => launchUrl(Uri.parse(termsOfServiceUrl), mode: LaunchMode.externalApplication),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            AppLocalizations.of(context).termsOfService,
                            style: const TextStyle(
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TwitchAccountButton extends StatelessWidget {
  final TwitchAccount twitchAccount;
  final bool active;

  const TwitchAccountButton({
    super.key,
    required this.twitchAccount,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        unawaited(context.read<Client>().connectAs(twitchAccount));

        final accountSettingsBox = Hive.box<dynamic>('AccountSettings');
        await accountSettingsBox.put('activeTwitchAccount', twitchAccount.tokenData.hash);
      },
      onLongPress: () {
        unawaited(
          Modal.show(
            context: context,
            child: TwitchAccountModal(
              twitchAccount: twitchAccount,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          children: [
            SizedBox(width: active ? 0.0 : 2.0),
            Material(
              borderRadius: BorderRadius.circular(24.0),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: active ? 40.0 : 36.0,
                height: active ? 40.0 : 36.0,
                child: twitchAccount.userData != null
                    ? Ink.image(
                        image: CachedNetworkImageProvider(twitchAccount.userData!.avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.question_mark_outlined),
              ),
            ),
            SizedBox(width: 16.0 + (active ? 0.0 : 2.0)),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(twitchAccount.userData?.displayName ?? twitchAccount.tokenData.login),
                Text(
                  AppLocalizations.of(context).loggedInVia('Twitch'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
