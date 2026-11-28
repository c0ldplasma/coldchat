import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/tile.dart';
import '../data/credits.dart';
import '../l10n/app_localizations.dart';
import 'about.dart';
import 'components/modal_header.dart';

class CreditsModal extends StatelessWidget {
  const CreditsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListView(
      shrinkWrap: true,
      children: [
        ModalHeader(title: l10n.credits),
        for (final credit in credits)
          Tile(
            title: credit.name,
            subtitle: switch (credit.language) {
              null => l10n.creditLogoDesigner,
              final language => l10n.creditTranslation(LocaleNames.of(context)?.nameOf(language) ?? language),
            },
            // Their initial: no picture to load from elsewhere.
            prefix: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(credit.name.characters.first.toUpperCase()),
            ),
            onTap: () => launchUrl(Uri.parse(credit.url), mode: LaunchMode.externalApplication),
          ),
        InkWell(
          onTap: () => launchUrl(Uri.parse(repositoryUrl), mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
            child: Text(
              l10n.creditsAiTranslations,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
