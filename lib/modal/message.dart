import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/twitch/twitch.dart';
import '../components/tile.dart';
import '../l10n/app_localizations.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/whispers/whisper_channel.dart';
import '../widgets/channel_view.dart';
import '../widgets/chat_message.dart';

class MessageModal extends StatelessWidget {
  final ChannelMessageChat message;
  final ChannelViewState? channelViewState;

  const MessageModal({
    super.key,
    required this.message,
    this.channelViewState,
  });

  // Whispers can't be replied to or deleted.
  bool get _whisper => message.channel is WhisperChannel;

  /// Only moderators and the broadcaster can delete messages on Twitch, not even their own, so the action is
  /// hidden for everyone else, like the ban and timeout row on the user card.
  bool get _canDelete {
    final channel = message.channel;
    if (channel == null || _whisper) return false;
    final tokenData = channel.client.transmitter.twitchAccount?.tokenData;
    if (tokenData?.accessToken == null) return false;
    return channel.canModerate(tokenData!.userId);
  }

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
            channelViewState?.setReplyChannelMessageChat(message);
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
            final l10n = AppLocalizations.of(context);
            Navigator.of(context).pop();
            final tokenData = message.channel!.client.transmitter.twitchAccount?.tokenData;
            // Logins from before ColdChat requested the scope can't delete messages until they sign in again.
            if (tokenData == null || !tokenData.scopes.contains(Twitch.deleteChatMessageScope)) {
              messenger.showSnackBar(SnackBar(content: Text(l10n.deleteMessageNeedsScope)));
              return;
            }
            try {
              await Twitch.deleteChatMessage(
                tokenData,
                broadcasterId: message.channel!.id!,
                moderatorId: tokenData.userId!,
                messageId: message.id,
              );
            } on TwitchRequestException catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    e.statusCode == 401 ? l10n.deleteMessageNeedsScope : l10n.deleteMessageFailed(e.message),
                  ),
                ),
              );
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text(l10n.deleteMessageFailed('$e'))));
            }
          },
        ),
      Tile(
        title: AppLocalizations.of(context).mentionUser,
        prefix: const Icon(Icons.alternate_email_outlined),
        onTap: () {
          Navigator.of(context).pop();
          channelViewState?.addSplit('@${message.user.login}');
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
