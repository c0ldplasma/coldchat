import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/twitch/helix_api.dart';
import '../api/twitch/twitch.dart';
import '../components/tile.dart';
import '../data/twitch/token_data.dart';
import '../l10n/app_localizations.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/moderation.dart';
import '../tmi/whispers/whisper_channel.dart';
import '../widgets/channel_view.dart';
import '../widgets/chat_message.dart';
import 'login_flow.dart';

/// Whether [tokenData] may delete messages. Logins from before ColdChat requested the scope can't until they sign
/// in again.
bool canDeleteMessagesWith(TokenData? tokenData) =>
    tokenData != null && tokenData.scopes.contains(HelixApi.deleteChatMessageScope);

/// Whether signing in again fixes a failed delete: Twitch answers 401 when the token lacks the scope.
bool deleteFailureNeedsSignIn(Object error) => error is TwitchRequestException && error.statusCode == 401;

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
            final navigator = Navigator.of(context);
            final l10n = AppLocalizations.of(context);
            navigator.pop();
            final failure = await deleteMessageAs(
              message.channel!.client.transmitter.twitchAccount?.tokenData,
              l10n,
              broadcasterId: message.channel!.id,
              messageId: message.id,
              helix: message.channel!.client.helix,
            );
            if (failure == null) return;
            if (failure.needsSignIn) {
              showSignInSnackBar(messenger, navigator, failure.text);
            } else {
              messenger.showSnackBar(SnackBar(content: Text(failure.text)));
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

/// Why deleting a message didn't work: the [text] to show, and whether signing in again fixes it.
typedef DeleteMessageFailure = ({String text, bool needsSignIn});

/// Deletes the message [messageId] in the channel [broadcasterId] as the account of [tokenData]. Returns null once
/// it's deleted, otherwise what to tell the user. [helix] is sent the request as [tokenData].
Future<DeleteMessageFailure?> deleteMessageAs(
  TokenData? tokenData,
  AppLocalizations l10n, {
  required String? broadcasterId,
  required String messageId,
  required HelixApi helix,
}) async {
  if (tokenData == null || !canDeleteMessagesWith(tokenData)) {
    return (text: l10n.deleteMessageNeedsScope, needsSignIn: true);
  }
  try {
    await helix
        .forToken(tokenData)
        .deleteChatMessage(broadcasterId: broadcasterId!, moderatorId: tokenData.userId!, messageId: messageId);
    return null;
  } on TwitchRequestException catch (e) {
    return deleteFailureNeedsSignIn(e)
        ? (text: l10n.deleteMessageNeedsScope, needsSignIn: true)
        : (text: l10n.deleteMessageFailed(e.message), needsSignIn: false);
  } catch (e) {
    return (text: l10n.deleteMessageFailed('$e'), needsSignIn: false);
  }
}
