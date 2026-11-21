import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/tile.dart';
import '../components/toggle.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';

class MessageAppearanceModal extends StatelessWidget {
  const MessageAppearanceModal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().changes,
    builder: (context, _) {
      final settings = context.read<SettingsRepository>();
      final messageAppearance = settings.messageAppearance;
      return ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: AppLocalizations.of(context).messageAppearance),
          Tile(
            prefix: const Icon(Icons.av_timer_rounded),
            title: AppLocalizations.of(context).showTimestamps,
            suffix: Toggle(
              value: messageAppearance.timestamps,
              onChanged: (value) {
                messageAppearance.timestamps = value;
                unawaited(settings.saveMessageAppearance(messageAppearance));
              },
            ),
            onTap: () {
              messageAppearance.timestamps = !messageAppearance.timestamps;
              unawaited(settings.saveMessageAppearance(messageAppearance));
            },
          ),
          Tile(
            prefix: const Icon(Icons.verified_outlined),
            title: AppLocalizations.of(context).showBadges,
            suffix: Toggle(
              value: messageAppearance.badges,
              onChanged: (value) {
                messageAppearance.badges = value;
                unawaited(settings.saveMessageAppearance(messageAppearance));
              },
            ),
            onTap: () {
              messageAppearance.badges = !messageAppearance.badges;
              unawaited(settings.saveMessageAppearance(messageAppearance));
            },
          ),
          Tile(
            prefix: const Icon(Icons.view_compact_outlined),
            title: AppLocalizations.of(context).compactMessages,
            suffix: Toggle(
              value: messageAppearance.compact,
              onChanged: (value) {
                messageAppearance.compact = value;
                unawaited(settings.saveMessageAppearance(messageAppearance));
              },
            ),
            onTap: () {
              messageAppearance.compact = !messageAppearance.compact;
              unawaited(settings.saveMessageAppearance(messageAppearance));
            },
          ),
          Slider(
            divisions: 24,
            min: 1.0,
            max: 4.0,
            value: messageAppearance.scale,
            label: '${messageAppearance.scale}',
            onChanged: (value) {
              messageAppearance.scale = value;
              unawaited(settings.saveMessageAppearance(messageAppearance));
            },
          ),
        ],
      );
    },
  );
}
