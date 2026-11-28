import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/tile.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';

/// What a long press on a channel's section in the emote picker offers: hiding the channel's emotes.
class EmoteSectionModal extends StatelessWidget {
  /// The channel's user id.
  final String channelId;

  /// The channel's name, the section's title.
  final String channelName;

  const EmoteSectionModal({super.key, required this.channelId, required this.channelName});

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      ModalHeader(title: channelName),
      Tile(
        title: AppLocalizations.of(context).hideEmoteSection,
        subtitle: AppLocalizations.of(context).hideEmoteSectionSubtitle,
        prefix: const Icon(Icons.visibility_off_outlined),
        onTap: () {
          unawaited(context.read<SettingsRepository>().hideEmoteChannel(channelId, channelName));
          Navigator.of(context).pop();
        },
      ),
    ],
  );
}

/// Settings → Chat → Hidden emote sections: the channels whose emotes are hidden from the picker, each to show again.
class HiddenEmoteSectionsModal extends StatelessWidget {
  const HiddenEmoteSectionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    return ListenableBuilder(
      listenable: settings.hiddenEmoteChannelsChanges,
      builder: (context, _) {
        final hidden = settings.hiddenEmoteChannels.entries.toList()
          ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
        return ListView(
          shrinkWrap: true,
          children: [
            ModalHeader(title: AppLocalizations.of(context).hiddenEmoteSections),
            if (hidden.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: Text(AppLocalizations.of(context).hiddenEmoteSectionsNone),
              ),
            for (final MapEntry(key: id, value: name) in hidden)
              Tile(
                title: name,
                prefix: const Icon(Icons.visibility_off_outlined),
                suffix: TextButton(
                  onPressed: () => settings.showEmoteChannel(id),
                  child: Text(AppLocalizations.of(context).showEmoteSection),
                ),
                onTap: () => settings.showEmoteChannel(id),
              ),
          ],
        );
      },
    );
  }
}
