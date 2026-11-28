import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/modal.dart';
import '../components/tile.dart';
import '../components/toggle.dart';
import '../data/emote_button_icon.dart';
import '../data/emote_cache.dart';
import '../data/emote_cache_cubit.dart';
import '../data/repositories/channel_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../tmi/client/client.dart';
import '../tools/megabytes.dart';
import '../widgets/chat/emote_picker.dart';
import '../widgets/emote_button_icon_view.dart';
import 'components/modal_header.dart';
import 'emote_section.dart';

/// Settings → Emotes: the emote panel's sections, the emote menu button, emote suggestions and the emote cache.
class EmoteSettingsModal extends StatelessWidget {
  const EmoteSettingsModal({super.key});

  // Offer the last opened channel's emotes too, not just global ones.
  Future<void> _pickButtonIcon(BuildContext context) {
    final client = context.read<Client>();
    final lastChannel = context.read<ChannelRepository>().lastChannel;
    final channel =
        client.channels.state.firstWhereOrNull((c) => c.name == lastChannel) ?? client.channels.state.firstOrNull;
    return Modal.show(
      context: context,
      child: Builder(
        builder: (modalContext) => SizedBox(
          height: 420.0,
          child: EmotePicker(
            client: client,
            channel: channel,
            getFieldInput: () => '',
            setFieldInput: (_) {},
            insertFieldInput: (_) {},
            onPickButtonIcon: (emote) async {
              if (await chooseEmoteButtonIcon(modalContext, emote) && modalContext.mounted) {
                Navigator.of(modalContext).pop();
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().changes,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final settings = context.read<SettingsRepository>();
      final emoteButtonIcon = context.read<EmoteButtonIcon>();
      final chatSettings = settings.chatSettings;
      final hiddenCount = settings.hiddenEmoteSections.length;
      return ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: l10n.emotes),
          Tile(
            title: l10n.emoteSections,
            subtitle: hiddenCount == 0 ? l10n.emoteSectionsSubtitle : l10n.emoteSectionsHiddenCount(hiddenCount),
            prefix: const Icon(Icons.reorder),
            suffix: const Icon(Icons.chevron_right),
            onTap: () => Modal.show(context: context, child: const EmoteSectionsModal()),
          ),
          Tile(
            title: l10n.emoteMenuButton,
            subtitle: emoteButtonIcon.name ?? 'Kappa',
            prefix: const SizedBox.square(dimension: 24.0, child: Center(child: EmoteButtonIconView())),
            suffix: const Icon(Icons.chevron_right),
            onTap: () => _pickButtonIcon(context),
          ),
          Tile(
            title: l10n.emoteMenuButtonGrayscale,
            prefix: const Icon(Icons.filter_b_and_w_outlined),
            suffix: Toggle(
              value: emoteButtonIcon.grayscale,
              onChanged: (newValue) => emoteButtonIcon.setGrayscale(!emoteButtonIcon.grayscale),
            ),
            onTap: () => emoteButtonIcon.setGrayscale(!emoteButtonIcon.grayscale),
          ),
          Tile(
            title: l10n.autocompleteEmotesWithColon,
            prefix: const Icon(Icons.emoji_emotions_outlined),
            suffix: Toggle(
              value: chatSettings.emoteAutocompletionWithColon,
              onChanged: (newValue) {
                chatSettings.emoteAutocompletionWithColon = !chatSettings.emoteAutocompletionWithColon;
                unawaited(settings.saveChatSettings(chatSettings));
              },
            ),
            onTap: () {
              chatSettings.emoteAutocompletionWithColon = !chatSettings.emoteAutocompletionWithColon;
              unawaited(settings.saveChatSettings(chatSettings));
            },
          ),
          const _EmoteCacheTile(),
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
          prefix: const Icon(Icons.storage_outlined),
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
