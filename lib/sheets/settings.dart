import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../components/modal.dart';
import '../components/tile.dart';
import '../components/toggle.dart';
import '../data/emote_cache.dart';
import '../data/emote_cache_cubit.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../tools/megabytes.dart';
import 'about.dart';
import 'application_appearance.dart';
import 'application_theme.dart';
import 'chat_settings.dart';
import 'components/modal_header.dart';
import 'credits.dart';
import 'custom_commands.dart';
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
      final accent = settings.accent;
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
                  title: l10n.accentColor,
                  subtitle: accent.name(l10n),
                  prefix: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  onTap: () => Modal.show(context: context, child: const ApplicationThemeModal()),
                ),
                Tile(
                  title: AppLocalizations.of(context).chatSettings,
                  prefix: const Icon(Icons.text_format_outlined),
                  onTap: () => Modal.show(context: context, child: const ChatSettingsModal()),
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
                const _EmoteCacheTile(),
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

/// The emote cache's size, with a button that empties it. Cleared images are downloaded again when shown.
class _EmoteCacheTile extends StatelessWidget {
  const _EmoteCacheTile();

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = EmoteCacheCubit.of(EmoteCacheManager.instance);
      unawaited(cubit.load());
      return cubit;
    },
    child: BlocBuilder<EmoteCacheCubit, EmoteCacheState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final locale = Localizations.localeOf(context).toLanguageTag();
        final bytes = state.bytes;
        return Tile(
          title: l10n.emoteCache,
          subtitle: bytes == null
              ? null
              : l10n.emoteCacheUsage(
                  l10n.megabytes(megabytes(bytes, locale)),
                  l10n.megabytes(megabytes(EmoteCacheManager.maxBytes, locale)),
                ),
          prefix: const Icon(Icons.emoji_emotions_outlined),
          suffix: IconButton(
            tooltip: l10n.clearCache,
            icon: const Icon(Icons.delete_outline),
            onPressed: state.clearing || bytes == 0 ? null : () => unawaited(context.read<EmoteCacheCubit>().clear()),
          ),
        );
      },
    ),
  );
}
