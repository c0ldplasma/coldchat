import 'package:coldchat/components/modal.dart';
import 'package:flutter/material.dart';
import 'package:coldchat/l10n/app_localizations.dart';

import '../components/tile.dart';
import '../tmi/whispers/whisper_channel.dart';
import 'user.dart';

/// Long-press on a whisper tab.
class WhisperModal extends StatelessWidget {
  final WhisperChannel conversation;

  const WhisperModal({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    final whispers = conversation.client.whispers;
    return ListView(
      shrinkWrap: true,
      children: [
        Tile(
          title: AppLocalizations.of(context)!.userCard,
          subtitle: conversation.partnerDisplayName,
          prefix: const Icon(Icons.person_outline_rounded),
          onTap: () {
            Modal.show(
              context: context,
              child: UserModal(login: conversation.partnerLogin, channel: conversation),
            );
          },
        ),
        Tile(
          title: AppLocalizations.of(context)!.closeConversation,
          subtitle: AppLocalizations.of(context)!.closeConversationSubtitle,
          prefix: const Icon(Icons.close_rounded),
          onTap: () {
            Navigator.of(context).pop();
            whispers.closeConversation(conversation);
          },
        ),
        Tile(
          title: AppLocalizations.of(context)!.deleteConversation,
          subtitle: AppLocalizations.of(context)!.deleteConversationSubtitle,
          prefix: const Icon(Icons.delete_outline_rounded),
          onTap: () {
            Navigator.of(context).pop();
            whispers.deleteConversation(conversation);
          },
        ),
      ],
    );
  }
}
