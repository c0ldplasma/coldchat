import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coldchat/l10n/app_localizations.dart';

import '/components/modal.dart';
import '/modal/about.dart';
import '/modal/login_flow.dart';
import '/modal/twitch_token_input.dart';

/// The home tab before any Twitch account is added: what ColdChat is and one button to sign in.
///
/// Long-pressing the button opens the access-token input instead, like long-pressing "Add another account" in the
/// account sheet. App review uses it to sign in without Twitch's email code.
class LoggedOutStart extends StatelessWidget {
  static const Color twitchPurple = Color(0xFF9146FF);

  const LoggedOutStart({super.key});

  void _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final linkStyle = theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The icon's artwork has light rounded corners of its own; clip a little inside them.
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: Transform.scale(scale: 1.06, child: Image.asset('assets/branding/app_icon.png', width: 96.0, height: 96.0, filterQuality: FilterQuality.medium)),
                ),
                const SizedBox(height: 24.0),
                Text(
                  l10n.appName,
                  style: theme.textTheme.headlineLarge?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  l10n.appTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 40.0),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: twitchPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => showTwitchLogin(context),
                    onLongPress: () => Modal.show(context: context, child: const TwitchTokenInputModal()),
                    icon: SvgPicture.asset('assets/emote_providers/twitch.svg', width: 20.0, height: 20.0, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                    label: Text(l10n.loginWithTwitch),
                  ),
                ),
                const SizedBox(height: 24.0),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _open(privacyPolicyUrl),
                      child: Text(l10n.privacyPolicy, style: linkStyle),
                    ),
                    Text('·', style: linkStyle),
                    TextButton(
                      onPressed: () => _open(termsOfServiceUrl),
                      child: Text(l10n.termsOfService, style: linkStyle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
