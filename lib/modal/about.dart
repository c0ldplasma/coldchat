import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/modal/components/modal_header.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/tile.dart';

const String repositoryUrl = 'https://github.com/c0ldplasma/coldchat';
const String copyrightNotice = '© Chatsen contributors\n© 2026 C0ldPlasma';

/// The notices the AGPL asks an interactive program to show: copyright, license, no warranty and where the
/// source is.
class AboutModal extends StatelessWidget {
  const AboutModal({super.key});

  void _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final version = info == null ? '' : '${info.version} (${info.buildNumber})';
          final legalese = '$copyrightNotice\n\n${AppLocalizations.of(context)!.aboutLegalese}';
          return ListView(
            shrinkWrap: true,
            children: [
              ModalHeader(title: AppLocalizations.of(context)!.about),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  '${AppLocalizations.of(context)!.appName} $version\n\n$legalese',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Tile(
                title: AppLocalizations.of(context)!.sourceCode,
                subtitle: info == null ? null : 'v${info.version}+${info.buildNumber}',
                prefix: const Icon(Icons.code_rounded),
                // Release builds are tagged with their version, so this opens the exact source of the
                // installed build.
                onTap: info == null ? null : () => _open('$repositoryUrl/tree/v${info.version}+${info.buildNumber}'),
              ),
              Tile(
                title: AppLocalizations.of(context)!.license,
                subtitle: 'GNU Affero General Public License v3.0',
                prefix: const Icon(Icons.gavel_rounded),
                onTap: () => _open('$repositoryUrl/blob/main/LICENSE'),
              ),
              Tile(
                title: AppLocalizations.of(context)!.basedOnChatsen,
                subtitle: 'github.com/chatsen/chatsen',
                prefix: const Icon(Icons.call_split_rounded),
                onTap: () => _open('https://github.com/chatsen/chatsen'),
              ),
              Tile(
                title: AppLocalizations.of(context)!.contact,
                subtitle: 'github.com/c0ldplasma/coldchat/issues',
                prefix: const Icon(Icons.mail_outline_rounded),
                onTap: () => _open('$repositoryUrl/issues'),
              ),
              Tile(
                title: AppLocalizations.of(context)!.openSourceLicenses,
                prefix: const Icon(Icons.description_outlined),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppLocalizations.of(context)!.appName,
                  applicationVersion: version,
                  applicationLegalese: legalese,
                ),
              ),
            ],
          );
        },
      );
}
