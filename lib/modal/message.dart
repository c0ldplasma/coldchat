import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/tile.dart';
import '../l10n/app_localizations.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/moderation.dart';
import '../tmi/whispers/whisper_channel.dart';
import '../widgets/chat_message.dart';
import 'login_flow.dart';

class MessageModal extends StatelessWidget {
  final ChannelMessageChat message;
  const MessageModal({
    super.key,
    required this.message,
  });

  // Whispers can't be replied to or deleted.
  bool get _whisper => message.channel is WhisperChannel;

  /// Only moderators and the broadcaster can delete messages on Twitch, not even their own, so the action is
  /// hidden for everyone else, like the ban and timeout row on the user card.
  bool get _canDelete => message.channel?.canModerateHere ?? false;

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ChatMessage(message: message),
      ),
      if (!_whisper)
        Tile(
          title: AppLocalizations.of(context).reply,
          prefix: const Icon(Icons.reply_outlined),
          onTap: () {
            Navigator.of(context).pop();
            message.channel?.composerDraft.replyTo(message);
          },
        ),
      Tile(
        title: AppLocalizations.of(context).copyText,
        subtitle: AppLocalizations.of(context).copyTextSubtitle,
        prefix: const Icon(Icons.copy_rounded),
        onTap: () async {
          Navigator.of(context).pop();
          await Clipboard.setData(ClipboardData(text: message.body));
        },
        onLongPress: () async {
          Navigator.of(context).pop();
          await Clipboard.setData(
            ClipboardData(
              text:
                  '${message.dateTime.hour}:${message.dateTime.minute.toString().padLeft(2, '0')} ${message.user.displayName}: ${message.body}',
            ),
          );
        },
      ),
      if (_canDelete)
        Tile(
          title: AppLocalizations.of(context).deleteMessage,
          prefix: const Icon(Icons.delete_outline_outlined),
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final l10n = AppLocalizations.of(context);
            navigator.pop();
            final failure = await message.channel!.deleteMessage(message.id);
            if (failure == null) return;
            final text = deleteFailureText(l10n, failure);
            if (failure.needsSignIn) {
              showSignInSnackBar(messenger, navigator, text);
            } else {
              messenger.showSnackBar(SnackBar(content: Text(text)));
            }
          },
        ),
      Tile(
        title: AppLocalizations.of(context).mentionUser,
        prefix: const Icon(Icons.alternate_email_outlined),
        onTap: () {
          Navigator.of(context).pop();
          final login = message.user.login;
          if (login != null) message.channel?.composerDraft.mention(login);
        },
      ),
      Tile(
        title: AppLocalizations.of(context).copyMessageId,
        prefix: const Icon(Icons.medical_information_outlined),
        onTap: () async {
          Navigator.of(context).pop();
          await Clipboard.setData(ClipboardData(text: message.id));
        },
      ),
    ],
  );
}

/// What to tell the user when deleting a message failed with [failure].
String deleteFailureText(AppLocalizations l10n, ModerationFailure failure) => switch (failure) {
  ModerationNeedsLogin() || ModerationNeedsScope() => l10n.deleteMessageNeedsScope,
  ModerationRequestFailed(:final reason) => l10n.deleteMessageFailed(reason),
};
