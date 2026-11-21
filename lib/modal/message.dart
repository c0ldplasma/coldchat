import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../api/twitch/twitch.dart';
import '../components/tile.dart';
import '../data/twitch/token_data.dart';
import '../l10n/app_localizations.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/moderation.dart';
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
    return canModerateAs(channel, channel?.client.transmitter.twitchAccount?.tokenData);
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
            final error = await deleteMessageAs(
              message.channel!.client.transmitter.twitchAccount?.tokenData,
              l10n,
              broadcasterId: message.channel!.id,
              messageId: message.id,
            );
            if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
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

/// Deletes the message [messageId] in the channel [broadcasterId] as the account of [tokenData] and returns the text
/// to show when that didn't work, or null once it's deleted. [client] is for tests.
Future<String?> deleteMessageAs(
  TokenData? tokenData,
  AppLocalizations l10n, {
  required String? broadcasterId,
  required String messageId,
  http.Client? client,
}) async {
  // Logins from before ColdChat requested the scope can't delete messages until they sign in again.
  if (tokenData == null || !tokenData.scopes.contains(Twitch.deleteChatMessageScope)) {
    return l10n.deleteMessageNeedsScope;
  }
  try {
    await Twitch.deleteChatMessage(
      tokenData,
      broadcasterId: broadcasterId!,
      moderatorId: tokenData.userId!,
      messageId: messageId,
      client: client,
    );
    return null;
  } on TwitchRequestException catch (e) {
    return e.statusCode == 401 ? l10n.deleteMessageNeedsScope : l10n.deleteMessageFailed(e.message);
  } catch (e) {
    return l10n.deleteMessageFailed('$e');
  }
}
