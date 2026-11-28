import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/modal.dart';
import '../components/surface.dart';
import '../data/emote.dart';
import '../data/emote_cache.dart';
import '../data/inline_url.dart';
import '../data/repositories/settings_repository.dart';
import '../data/settings/message_appearance.dart';
import '../l10n/app_localizations.dart';
import '../sheets/emote.dart';
import '../sheets/message.dart';
import '../sheets/user.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/channel/channel_message.dart';
import '../tmi/channel/channel_state.dart';
import '../tmi/channel/messages/channel_message_ban.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/channel/messages/channel_message_embeds.dart';
import '../tmi/channel/messages/channel_message_event.dart';
import '../tmi/channel/messages/channel_message_notice.dart';
import '../tmi/channel/messages/channel_message_state_change.dart';
import '../tmi/channel/messages/embeds/image_embed.dart';
import '../tools/clock_time.dart';
import 'chat/chat_ban_chip.dart';
import 'chat/chat_notice_chip.dart';
import 'chat/reply_painter.dart';
import 'embeds/link_image.dart';
import 'emote_stack_view.dart';

class BlockedChatMessage extends StatefulWidget {
  final Widget widget;
  final MessageAppearance messageAppearance;

  const BlockedChatMessage({
    super.key,
    required this.widget,
    required this.messageAppearance,
  });

  @override
  State<BlockedChatMessage> createState() => _BlockedChatMessageState();
}

class _BlockedChatMessageState extends State<BlockedChatMessage> {
  bool hidden = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 2.0 * (widget.messageAppearance.compact ? 1.0 : 2.0),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: AppLocalizations.of(context).blockedMessage),
                    const TextSpan(text: ''),
                    TextSpan(
                      text: hidden
                          ? AppLocalizations.of(context).showMessage
                          : AppLocalizations.of(context).hideMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      // recognizer: TapGestureRecognizer()
                      //   ..onTap = () => setState
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0) * widget.messageAppearance.scale,
                ),
              ),
            ),
            if (!hidden) widget.widget,
          ],
        ),
        onTap: () => setState(() => hidden = !hidden),
      ),
    );
  }
}

class ChatMessage extends StatefulWidget {
  // Twitch's classic text emoticons (the smiley set) are tiny glyph images
  // and look oversized when rendered at the same height as named emotes like
  // Kappa/PogChamp, so they get a smaller, near-text height.
  static const Set<String> _twitchClassicEmoticons = {
    ':)',
    ':(',
    ':D',
    '>(',
    ':|',
    'O_o',
    'B)',
    ':O',
    '<3',
    ':/',
    ';)',
    ':P',
    ';P',
    'R)',
    ':-)',
    ':-(',
    ':-D',
    '>:(',
    ':-|',
    'O_O',
    'B-)',
    ':-O',
    ':-/',
    ';-)',
    ':-P',
    ';-P',
    'R-)',
    ':7',
    ':>',
    ':S',
    '#/',
    '<]',
    ':z',
  };

  final ChannelMessage message;
  final bool renderMentions;

  const ChatMessage({
    super.key,
    required this.message,
    this.renderMentions = true,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  // The tap recognizers of the text spans (the user name and links) belong to this state, so they are disposed with
  // it. A recognizer created in build and never disposed outlives its element: when a message's element goes away (a
  // pending message replaced by the sent one, a message dropped from the list) a tap that ended after that ran its
  // callback with an unmounted context (Navigator.of then failed a null check). Disposing a recognizer cancels a tap it
  // is still tracking.
  TapGestureRecognizer? _nameRecognizer;
  final Map<String, TapGestureRecognizer> _urlRecognizers = {};

  TapGestureRecognizer get _nameTap => _nameRecognizer ??= TapGestureRecognizer()..onTap = _openUserCard;

  TapGestureRecognizer _urlTap(String url) => _urlRecognizers.putIfAbsent(
    url,
    () =>
        TapGestureRecognizer()
          ..onTap = () => unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
  );

  void _openUserCard() {
    final message = widget.message;
    if (!mounted || message is! ChannelMessageChat) return;
    unawaited(
      Modal.show(
        context: context,
        child: UserModal(
          login: message.message.prefix!.split('!').first,
          channel: message.channel,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(ChatMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) _disposeUrlRecognizers();
  }

  void _disposeUrlRecognizers() {
    for (final recognizer in _urlRecognizers.values) {
      recognizer.dispose();
    }
    _urlRecognizers.clear();
  }

  @override
  void dispose() {
    _nameRecognizer?.dispose();
    _disposeUrlRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageAppearance = context.read<SettingsRepository>().messageAppearance;
    if (widget.message is ChannelMessageChat) {
      final chatMessage = widget.message as ChannelMessageChat;
      if (chatMessage.subInfo != null) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0 * (messageAppearance.compact ? 1.0 : 2.0)),
          child: Wrap(
            alignment: WrapAlignment.start,
            children: [
              Surface(
                type: SurfaceType.tertiary,
                borderRadius: BorderRadius.circular(18.0 * messageAppearance.scale),
                onTap: () async {},
                onLongPress: () => Modal.show(
                  context: context,
                  child: MessageModal(message: chatMessage),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0 * messageAppearance.scale,
                    vertical: 8.0 * messageAppearance.scale,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(
                                chatMessage.subInfo!.msgParamWasGifted
                                    ? Icons.card_giftcard_outlined
                                    : Icons.star_border_outlined,
                                size: Theme.of(context).textTheme.titleLarge!.fontSize! * messageAppearance.scale,
                              ),
                            ),
                            WidgetSpan(
                              child: SizedBox(
                                height: 8.0 * messageAppearance.scale,
                                width: 8.0 * messageAppearance.scale,
                              ),
                            ),
                            TextSpan(text: '${chatMessage.subInfo?.systemMsg}'),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.bodyMedium!.fontSize! * messageAppearance.scale,
                        ),
                      ),
                      _buildMessageContent(chatMessage, messageAppearance),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final content = Surface(
        type: chatMessage.blocked
            ? SurfaceType.error
            : chatMessage.mentionned && widget.renderMentions
            ? SurfaceType.primary
            : SurfaceType.transparent,
        onTap: () async {},
        onLongPress: () => Modal.show(
          context: context,
          child: MessageModal(message: chatMessage),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0 * (messageAppearance.compact ? 1.0 : 2.0)),
          child: _buildMessageContent(chatMessage, messageAppearance),
        ),
      );
      if (chatMessage.blocked) {
        return BlockedChatMessage(
          widget: content,
          messageAppearance: messageAppearance,
        );
      }

      return content;
    } else if (widget.message is ChannelMessageBan) {
      return ChatBanChip(messageAppearance: messageAppearance, message: widget.message as ChannelMessageBan);
    } else if (widget.message is ChannelMessageNotice) {
      return ChatNoticeChip(messageAppearance: messageAppearance, message: widget.message as ChannelMessageNotice);
    } else if (widget.message is ChannelMessageEvent) {
      return Container();
    } else if (widget.message is ChannelMessageStateChange) {
      return _ChannelStatusLine(
        message: widget.message as ChannelMessageStateChange,
        messageAppearance: messageAppearance,
      );
    }
    return Text('Unhandled message type: ${widget.message.runtimeType}'); // Not translated: a bug report, never shown.
  }

  static Widget _emoteImage(Emote emote, MessageAppearance messageAppearance) => Image(
    image: CachedNetworkImageProvider(emote.mipmap.last, cacheManager: EmoteCacheManager.instance),
    height:
        (emote.source.name == 'Emoji' ||
                (emote.source.name == 'Twitch' && ChatMessage._twitchClassicEmoticons.contains(emote.name))
            ? 24.0
            : 32.0) *
        (1.0 / messageAppearance.scale),
    filterQuality: FilterQuality.high,
  );

  Widget _buildMessageContent(ChannelMessageChat message, MessageAppearance messageAppearance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.replyInfo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                if (messageAppearance.timestamps) SizedBox(width: 8.0 * messageAppearance.scale),
                CustomPaint(
                  painter: ReplyPainter(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2.0 * messageAppearance.scale,
                  ),
                  child: SizedBox(
                    height: 15.0 * messageAppearance.scale,
                    width: 30.0 * messageAppearance.scale,
                  ),
                ),
                SizedBox(width: 8.0 * messageAppearance.scale),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '@${message.replyInfo?.replyParentDisplayName}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '${message.replyInfo?.replyParentMsgBody}'),
                        // TextSpan(text: '${message.replyInfo?.replyParentMsgBody}'),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0) * messageAppearance.scale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text.rich(
          TextSpan(
            children: [
              if (messageAppearance.timestamps)
                TextSpan(
                  text: '${clockTimeOf(context, message.dateTime)}  ',
                  style: TextStyle(
                    color: ChatColors.of(context).muted,
                    fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0) * messageAppearance.scale,
                  ),
                ),
              if (messageAppearance.badges)
                for (final badge in message.badges)
                  WidgetSpan(
                    child: Tooltip(
                      message: badge.name,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4.0 * messageAppearance.scale),
                        child: badge.mipmap.last.endsWith('.svg')
                            ? SvgPicture.network(
                                badge.mipmap.last,
                                height: 20.0 * messageAppearance.scale,
                              )
                            : Image(
                                image: CachedNetworkImageProvider(
                                  badge.mipmap.last,
                                  cacheManager: EmoteCacheManager.instance,
                                ),
                                height: 20.0 * messageAppearance.scale,
                              ),
                      ),
                    ),
                  ),
              TextSpan(
                text: '${message.user.displayName}: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0) * messageAppearance.scale,
                  color: ChatColors.of(context).nameColor(message.user.color, Theme.of(context).colorScheme),
                ),
                recognizer: _nameTap,
              ),
              for (final split in message.splits) ...[
                if (split is String)
                  TextSpan(
                    text: '$split ',
                    style: TextStyle(
                      fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0) * messageAppearance.scale,
                    ),
                  ),
                if (split is Emote)
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Modal.show(
                        context: context,
                        child: EmoteModal(emote: split),
                      ),
                      child: Tooltip(
                        message: split.name,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0) * messageAppearance.scale,
                          child: _emoteImage(split, messageAppearance),
                        ),
                      ),
                    ),
                  ),
                if (split is EmoteStack)
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Modal.show(
                        context: context,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [for (final emote in split.emotes) EmoteModal(emote: emote)],
                        ),
                      ),
                      child: Tooltip(
                        message: split.emotes.map((emote) => emote.name).join(' '),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0) * messageAppearance.scale,
                          child: EmoteStackView(stack: split, image: (emote) => _emoteImage(emote, messageAppearance)),
                        ),
                      ),
                    ),
                  ),
                if (split is InlineUrl)
                  TextSpan(
                    text: '${split.url} ',
                    style: TextStyle(
                      color: ChatColors.of(context).link,
                      decoration: TextDecoration.underline,
                      decorationColor: ChatColors.of(context).link,
                      fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0) * messageAppearance.scale,
                    ),
                    recognizer: _urlTap(split.url),
                  ),
              ],
            ],
          ),
        ),
        BlocBuilder<ChannelMessageEmbedsCubit, List<dynamic>>(
          bloc: message.embeds,
          builder: (BuildContext context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isNotEmpty) SizedBox(height: 8.0 * messageAppearance.scale),
              for (final embed in state) ...[
                if (embed is ImageEmbed) LinkImage(embed: embed, scale: messageAppearance.scale),
                SizedBox(height: 8.0 * messageAppearance.scale),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The connection status at the end of a channel's chat ("Connected to #name"), laid out like a chat message: same
/// padding, the time in front when timestamps are on, in a quieter color.
class _ChannelStatusLine extends StatelessWidget {
  final ChannelMessageStateChange message;
  final MessageAppearance messageAppearance;

  const _ChannelStatusLine({required this.message, required this.messageAppearance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final channel = message.channel?.name ?? '';
    final text = switch (message.change.nextState) {
      ChannelConnecting() => l10n.channelConnecting(channel),
      ChannelConnected() => l10n.channelConnected(channel),
      ChannelSuspended() => l10n.channelSuspended(channel),
      ChannelBanned() => l10n.channelBanned(channel),
      _ => l10n.channelDisconnected(channel),
    };
    final fontSize = (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0) * messageAppearance.scale;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0 * (messageAppearance.compact ? 1.0 : 2.0)),
      child: Text.rich(
        TextSpan(
          children: [
            if (messageAppearance.timestamps) TextSpan(text: '${clockTimeOf(context, message.dateTime)}  '),
            TextSpan(
              text: text,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        style: TextStyle(color: color, fontSize: fontSize),
      ),
    );
  }
}
