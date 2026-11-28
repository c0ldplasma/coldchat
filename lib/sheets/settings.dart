import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../components/modal.dart';
import '../components/tile.dart';
import '../components/toggle.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'about.dart';
import 'application_appearance.dart';
import 'chat_settings.dart';
import 'components/modal_header.dart';
import 'credits.dart';
import 'custom_commands.dart';
import 'emote_settings.dart';
import 'language_selection.dart';
import 'message_appearance.dart';
import 'message_triggers.dart';
import 'user_triggers.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().changes,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final settings = context.read<SettingsRepository>();
      final themeMode = settings.applicationAppearance.themeMode;
      // The header stays put; only the entries below it scroll when they don't fit.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalHeader(title: l10n.settings),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                Tile(
                  title: l10n.appearance,
                  subtitle: switch (themeMode) {
                    'light' => l10n.light,
                    'dark' => l10n.dark,
                    _ => l10n.system,
                  },
                  prefix: Icon(switch (themeMode) {
                    'light' => Icons.light_mode_outlined,
                    'dark' => Icons.dark_mode_outlined,
                    _ => Icons.phone_android_outlined,
                  }),
                  onTap: () => Modal.show(context: context, child: const ApplicationAppearanceModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).chatSettings,
                  prefix: const Icon(Icons.text_format_outlined),
                  onTap: () => Modal.show(context: context, child: const ChatSettingsModal()),
                ),
                Tile(
                  title: l10n.emotes,
                  prefix: const Icon(Icons.emoji_emotions_outlined),
                  onTap: () => Modal.show(context: context, child: const EmoteSettingsModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).language,
                  subtitle:
                      LocaleNamesLocalizationsDelegate.nativeLocaleNames[AppLocalizations.supportedLocales
                          .firstWhereOrNull((element) => element.toLanguageTag() == settings.locale)
                          .toString()] ??
                      AppLocalizations.of(context).systemDefault,
                  prefix: const Icon(Icons.language_outlined),
                  onTap: () => Modal.show(context: context, child: const LanguageSelectionModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).messageAppearance,
                  prefix: const Icon(Icons.font_download_rounded),
                  onTap: () => Modal.show(context: context, child: const MessageAppearanceModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).customCommands,
                  prefix: const Icon(Icons.terminal_rounded),
                  onTap: () => Modal.show(context: context, child: const CustomCommandsModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).messageTriggers,
                  prefix: const Icon(Icons.message_rounded),
                  onTap: () => Modal.show(context: context, child: const MessageTriggersModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).userTriggers,
                  prefix: const Icon(Icons.person_outline_rounded),
                  onTap: () => Modal.show(context: context, child: const UserTriggersModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).credits,
                  prefix: const Icon(Icons.work_outline_outlined),
                  onTap: () => Modal.show(context: context, child: const CreditsModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).about,
                  prefix: const Icon(Icons.info_outline_rounded),
                  onTap: () => Modal.show(context: context, child: const AboutModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).chatHistory,
                  prefix: const Icon(Icons.history),
                  suffix: Toggle(
                    value: settings.chatHistory,
                    onChanged: settings.setChatHistory,
                  ),
                  onTap: () => settings.setChatHistory(!settings.chatHistory),
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        info == null
                            ? ''
                            : '${AppLocalizations.of(context).appName} ${info.version} (${info.buildNumber})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
