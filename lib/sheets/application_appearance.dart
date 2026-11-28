import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/modal.dart';
import '../components/tile.dart';
import '../components/toggle.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'application_theme.dart';
import 'components/modal_header.dart';

class ApplicationAppearanceModal extends StatelessWidget {
  const ApplicationAppearanceModal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().changes,
    builder: (context, _) {
      final settings = context.read<SettingsRepository>();
      final applicationAppearance = settings.applicationAppearance;
      return ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: AppLocalizations.of(context).appearance),
          Tile(
            prefix: const Icon(Icons.light_mode_outlined),
            title: AppLocalizations.of(context).light,
            onTap: () {
              applicationAppearance.themeMode = 'light';
              unawaited(settings.saveApplicationAppearance(applicationAppearance));
            },
            suffix: applicationAppearance.themeMode == 'light'
                ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          Tile(
            prefix: const Icon(Icons.dark_mode_outlined),
            title: AppLocalizations.of(context).dark,
            onTap: () {
              applicationAppearance.themeMode = 'dark';
              unawaited(settings.saveApplicationAppearance(applicationAppearance));
            },
            suffix: applicationAppearance.themeMode == 'dark'
                ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          Tile(
            prefix: const Icon(Icons.phone_android_outlined),
            title: AppLocalizations.of(context).system,
            onTap: () {
              applicationAppearance.themeMode = 'system';
              unawaited(settings.saveApplicationAppearance(applicationAppearance));
            },
            suffix: applicationAppearance.themeMode == 'system'
                ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          Tile(
            title: AppLocalizations.of(context).accentColor,
            subtitle: settings.accent.name(AppLocalizations.of(context)),
            prefix: Padding(
              padding: const EdgeInsets.all(6.0),
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            suffix: const Icon(Icons.chevron_right),
            onTap: () => Modal.show(context: context, child: const ApplicationThemeModal()),
          ),
          Tile(
            prefix: const Icon(Icons.contrast_rounded),
            title: AppLocalizations.of(context).oledBlack,
            subtitle: AppLocalizations.of(context).oledBlackSubtitle,
            onTap: () {
              applicationAppearance.oledBlack = !applicationAppearance.oledBlack;
              unawaited(settings.saveApplicationAppearance(applicationAppearance));
            },
            suffix: Toggle(
              value: applicationAppearance.oledBlack,
              onChanged: (value) {
                applicationAppearance.oledBlack = value;
                unawaited(settings.saveApplicationAppearance(applicationAppearance));
              },
            ),
          ),
          Tile(
            prefix: const Icon(Icons.blinds_closed_outlined),
            title: AppLocalizations.of(context).highContrast,
            onTap: () {
              applicationAppearance.highContrast = !applicationAppearance.highContrast;
              unawaited(settings.saveApplicationAppearance(applicationAppearance));
            },
            suffix: Toggle(
              value: applicationAppearance.highContrast,
              onChanged: (value) {
                applicationAppearance.highContrast = value;
                unawaited(settings.saveApplicationAppearance(applicationAppearance));
              },
            ),
          ),
        ],
      );
    },
  );
}
