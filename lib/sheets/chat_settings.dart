import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/tile.dart';
import '../components/toggle.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';

class ChatSettingsModal extends StatelessWidget {
  const ChatSettingsModal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().changes,
    builder: (context, _) {
      final settings = context.read<SettingsRepository>();
      final chatSettings = settings.chatSettings;
      return ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: AppLocalizations.of(context).chatSettings),
          Tile(
            title: AppLocalizations.of(context).autocompleteUsersWithAt,
            prefix: const Icon(Icons.alternate_email_outlined),
            suffix: Toggle(
              value: chatSettings.userAutocompletionWithAt,
              onChanged: (newValue) {
                chatSettings.userAutocompletionWithAt = !chatSettings.userAutocompletionWithAt;
                unawaited(settings.saveChatSettings(chatSettings));
              },
            ),
            onTap: () {
              chatSettings.userAutocompletionWithAt = !chatSettings.userAutocompletionWithAt;
              unawaited(settings.saveChatSettings(chatSettings));
            },
          ),
          Tile(
            title: AppLocalizations.of(context).showImagesFromLinks,
            subtitle: AppLocalizations.of(context).showImagesFromLinksSubtitle,
            prefix: const Icon(Icons.image_outlined),
            suffix: Toggle(
              value: chatSettings.showLinkImages,
              onChanged: (newValue) {
                chatSettings.showLinkImages = !chatSettings.showLinkImages;
                unawaited(settings.saveChatSettings(chatSettings));
              },
            ),
            onTap: () {
              chatSettings.showLinkImages = !chatSettings.showLinkImages;
              unawaited(settings.saveChatSettings(chatSettings));
            },
          ),
        ],
      );
    },
  );
}
