import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/tile.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';

/// What a long press on a section in the emote picker offers: hiding its emotes.
class EmoteSectionModal extends StatelessWidget {
  /// The section's key, see `emoteSectionKey`.
  final String sectionKey;

  /// The section's title, e.g. a channel's name or `7TV`.
  final String title;

  const EmoteSectionModal({super.key, required this.sectionKey, required this.title});

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      ModalHeader(title: title),
      Tile(
        title: AppLocalizations.of(context).hideEmoteSection,
        subtitle: AppLocalizations.of(context).hideEmoteSectionSubtitle,
        prefix: const Icon(Icons.visibility_off_outlined),
        onTap: () {
          unawaited(context.read<SettingsRepository>().hideEmoteSection(sectionKey, title));
          Navigator.of(context).pop();
        },
      ),
    ],
  );
}

/// Settings → Chat → Hidden emote sections: the picker's sections whose emotes are hidden, each to show again.
class HiddenEmoteSectionsModal extends StatelessWidget {
  const HiddenEmoteSectionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    return ListenableBuilder(
      listenable: settings.hiddenEmoteSectionsChanges,
      builder: (context, _) {
        final hidden = settings.hiddenEmoteSections.entries.toList()
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
            for (final MapEntry(:key, value: title) in hidden)
              Tile(
                title: title,
                prefix: const Icon(Icons.visibility_off_outlined),
                suffix: TextButton(
                  onPressed: () => settings.showEmoteSection(key),
                  child: Text(AppLocalizations.of(context).showEmoteSection),
                ),
                onTap: () => settings.showEmoteSection(key),
              ),
          ],
        );
      },
    );
  }
}
