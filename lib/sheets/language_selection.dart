import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:provider/provider.dart';

import '../components/tile.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';

class LanguageSelectionModal extends StatelessWidget {
  const LanguageSelectionModal({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      ModalHeader(title: AppLocalizations.of(context).language),
      Tile(
        title: AppLocalizations.of(context).justDefault, // locale.toLanguageTag(),
        subtitle: AppLocalizations.of(context).systemDefault,
        prefix: const Icon(Icons.phone_android_outlined),
        onTap: () => context.read<SettingsRepository>().setLocale(null),
      ),
      for (final locale in AppLocalizations.supportedLocales)
        Tooltip(
          message: locale.toLanguageTag(),
          child: Tile(
            title: LocaleNames.of(context)!.nameOf(locale.toString()) ?? locale.toString(),
            subtitle: LocaleNamesLocalizationsDelegate.nativeLocaleNames[locale.toString()],
            prefix: const Icon(Icons.language_outlined),
            onTap: () => context.read<SettingsRepository>().setLocale(locale.toLanguageTag()),
          ),
        ),
    ],
  );
}
