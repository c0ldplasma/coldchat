import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../data/custom_badge.dart';
import '../../../data/emote.dart';
import '../../../data/inline_url.dart';
import '../../../data/message_trigger.dart';
import '../../../data/user_trigger.dart';
import '../../../irc/message.dart' as irc;
import '../../../providers/twitch.dart';
import '../../user.dart';
import '../channel_message.dart';
import 'channel_message_embeds.dart';
import 'channel_message_id.dart';
import 'channel_message_user.dart';
import 'embeds/image_embed.dart';

class TwitchEmoteInstance {
  final String code;
  final int start;
  final int end;

  TwitchEmoteInstance({
    required this.code,
    required this.start,
    required this.end,
  });
}

class ChannelMessageChatReplyInfo {
  String replyParentDisplayName; // SupDos
  String replyParentMsgBody; // peepoLeave
  String replyParentMsgId; // a11f6f0d-e4ad-4f61-a5b8-58a848ef2f7e
  String replyParentUserId; // 43983992
  String replyParentUserLogin; // supdos

  ChannelMessageChatReplyInfo({
    required this.replyParentDisplayName,
    required this.replyParentMsgBody,
    required this.replyParentMsgId,
    required this.replyParentUserId,
    required this.replyParentUserLogin,
  });
}

class ChannelMessageChatSubInfo {
  String systemMsg;
  bool msgParamWasGifted;

  ChannelMessageChatSubInfo({
    required this.systemMsg,
    required this.msgParamWasGifted,
  });
}

class ChannelMessageChat extends ChannelMessage with ChannelMessageUser, ChannelMessageEmbeds, ChannelMessageId {
  // Hoisted out of build() so they are compiled/allocated once instead of per
  // message (or, for the url regexes, per word) during history deserialization.
  static final RegExp _actionRegex = RegExp('ACTION .*');
  static final RegExp _imageRegex = RegExp(r'\.(png|apng|gif|webp|jpg|jpeg)$');
  static final TwitchProvider _twitchProvider = TwitchProvider();

  irc.Message message;
  bool action = false;
  List<dynamic> splits = [];
  List<CustomBadge> badges = [];
  String body = '';
  ChannelMessageChatReplyInfo? replyInfo;
  ChannelMessageChatSubInfo? subInfo;
  bool mentionned = false;
  bool blocked = false;

  ChannelMessageChat({
    required this.message,
    required super.dateTime,
    super.channel,
  }) {
    build();
  }

  void build() {
    badges.clear();
    splits.clear();
    embeds.clear();

    // TODO: Ensure there is always an id at this stage?
    id = message.tags['id']!;

    if (message.tags['reply-parent-display-name'] != null) {
      try {
        replyInfo = ChannelMessageChatReplyInfo(
          replyParentDisplayName: message.tags['reply-parent-display-name']!,
          replyParentMsgBody: message.tags['reply-parent-msg-body']!,
          replyParentMsgId: message.tags['reply-parent-msg-id']!,
          replyParentUserId: message.tags['reply-parent-user-id']!,
          replyParentUserLogin: message.tags['reply-parent-user-login']!,
        );
      } catch (e) {
        // ignore
      }
    }

    if (message.tags['system-msg'] != null && message.tags['msg-param-was-gifted'] != null) {
      try {
        subInfo = ChannelMessageChatSubInfo(
          systemMsg: message.tags['system-msg']!,
          msgParamWasGifted: message.tags['msg-param-was-gifted']! != 'false',
        );
      } catch (e) {
        // ignore
      }
    }

    user = User(
      login: message.prefix!.split('!').first,
      displayName: message.tags['display-name'],
      id: message.tags['user-id'],
      color: (message.tags['color']?.isEmpty ?? true)
          ? null
          : Color(int.parse('FF${message.tags['color']!.substring(1)}', radix: 16)),
    );

    var messageText = message.parameters.skip(1).join(':');

    if (messageText.contains(_actionRegex)) action = true;
    if (action) messageText = messageText.substring('ACTION '.length, messageText.length - 1);

    // Some clients (Chatterino style) escape U+200D (ZERO WIDTH JOINER) as U+E0002; turn it back into a ZWJ so
    // emoji ZWJ sequences render. ColdChat itself sends ZWJ unchanged (see Channel.send).
    // alternative regex for replacement: (?<!\U000E0002)\U000E0002
    final replacement = String.fromCharCodes(Runes('\u{e0002}'));
    final zeroWidthJoiner = String.fromCharCodes(Runes('\u{200d}'));
    messageText = messageText.replaceAll(replacement, zeroWidthJoiner);

    body = messageText;

    final messageRunes = messageText.runes.toList();

    try {
      final twitchEmotes = <TwitchEmoteInstance>[];
      for (final twitchEmoteData in (message.tags['emotes']?.split('/') ?? []).where((element) => element.isNotEmpty)) {
        final twitchEmoteCodeAndInstances = twitchEmoteData.split(':');
        final twitchEmoteCode = twitchEmoteCodeAndInstances.first;
        final twitchEmoteInstances = twitchEmoteCodeAndInstances.last.split(',').map((instance) => instance.split('-'));
        for (final twitchEmoteInstanceData in twitchEmoteInstances) {
          twitchEmotes.add(
            TwitchEmoteInstance(
              code: twitchEmoteCode,
              start: int.parse(twitchEmoteInstanceData.first),
              end: int.parse(twitchEmoteInstanceData.last),
            ),
          );
        }
      }

      twitchEmotes.sort((item, item2) => item2.start.compareTo(item.start));

      for (var twitchEmote in twitchEmotes) {
        messageRunes.replaceRange(
          twitchEmote.start,
          twitchEmote.end + 1,
          ' ${twitchEmote.code}|${String.fromCharCodes(messageRunes.getRange(twitchEmote.start, twitchEmote.end + 1))} '
              .runes,
        );
      }

      messageText = String.fromCharCodes(messageRunes).replaceAll(utf8.decode([0xF3, 0xA0, 0x80, 0x80]), '');
    } catch (e) {
      log('Couldn\'t parse Twitch emote data: ${message.tags['emotes']} -> $e');
    }

    final badgeLookup = channel?.badgeLookup ?? const <String, CustomBadge>{};
    final twitchBadges = message.tags['badges']?.split(',') ?? [];
    for (final twitchBadgeId in twitchBadges) {
      final badge = badgeLookup[twitchBadgeId];
      if (badge != null) badges.add(badge);
    }

    final userId = user.id;
    if (userId != null) badges.addAll(channel?.client.globals.userBadges.badgesOf(userId) ?? const []);

    final bttvProBadge = channel?.client.globals.bttvProBadges[user.id];
    if (bttvProBadge != null) badges.add(bttvProBadge);

    final emoteLookup = channel?.emoteLookup ?? const <String, Emote>{};
    var textSplits = messageText.split(' ').where((split) => split.isNotEmpty);
    if (replyInfo != null) textSplits = textSplits.skip(1);

    for (final textSplit in textSplits) {
      var emote = emoteLookup[textSplit];
      if (textSplit.startsWith('')) {
        final emoteData = textSplit.substring(1).split('|');
        emote = Emote(
          id: emoteData.first,
          mipmap: [
            'https://static-cdn.jtvnw.net/emoticons/v2/${emoteData.first}/default/dark/1.0',
            'https://static-cdn.jtvnw.net/emoticons/v2/${emoteData.first}/default/dark/2.0',
            'https://static-cdn.jtvnw.net/emoticons/v2/${emoteData.first}/default/dark/3.0',
          ],
          name: emoteData.last,
          provider: _twitchProvider,
        );
      }

      final uri = textSplit.startsWith('http') ? Uri.tryParse(textSplit) : null;

      if (emote != null) {
        _addEmote(emote);
      } else if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        splits.add(InlineUrl(url: '$uri'));
        if (_imageRegex.hasMatch('${uri.removeFragment()}')) {
          embeds.add(ImageEmbed(url: '$uri'));
        }
      } else {
        splits.add(textSplit);
      }
    }

    // Check whether the user got mentionned or if the message should be blocked
    mentionned = false;
    blocked = false;

    final client = channel?.client;
    if (client != null) {
      // Check user triggers
      final triggers = client.triggers;
      final userTrigger = triggers?.userTriggerFor(user.login);
      if (userTrigger != null) {
        switch (UserTriggerType.values[userTrigger.type]) {
          case UserTriggerType.mention:
            mentionned = true;
            break;
          case UserTriggerType.block:
            blocked = true;
            break;
        }
      }

      // Check message triggers
      final messageTriggers = triggers?.messageTriggers ?? const <MessageTrigger>[];
      final messageTrigger = messageTriggers.firstWhereOrNull((messageTrigger) {
        if (messageTrigger.enableRegex) {
          return messageTrigger.matchesRegex(body);
        } else {
          var pattern = messageTrigger.pattern;
          if (!messageTrigger.caseSensitive) {
            pattern = messageTrigger.pattern.toLowerCase();
            if (textSplits.length > 1) {
              return body.toLowerCase().contains(pattern);
            } else {
              return textSplits
                  .whereType<String>()
                  .map((e) => e.toLowerCase())
                  .any(
                    (split) =>
                        split == pattern || split == '@$pattern' || split == '$pattern,' || split == '@$pattern,',
                  );
            }
          } else {
            if (textSplits.length > 1) {
              return body.contains(pattern);
            } else {
              return textSplits.whereType<String>().any(
                (split) => split == pattern || split == '@$pattern' || split == '$pattern,' || split == '@$pattern,',
              );
            }
          }
        }
      });
      if (messageTrigger != null) {
        switch (MessageTriggerType.values[messageTrigger.type]) {
          case MessageTriggerType.mention:
            mentionned = true;
            break;
          case MessageTriggerType.block:
            blocked = true;
            break;
        }
      }

      // The own account is the transmitter's; the receiver reading the chat is anonymous.
      final userId = user.id;
      blocked = blocked || (userId != null && client.session.isBlocked(userId));
      final ownLogin = client.session.ownLogin;
      if (ownLogin != null) {
        mentionned =
            mentionned ||
            textSplits
                .whereType<String>()
                .map((e) => e.toLowerCase())
                .any(
                  (split) =>
                      split == ownLogin || split == '@$ownLogin' || split == '$ownLogin,' || split == '@$ownLogin,',
                );
      }
    }
  }

  /// Adds [emote] to [splits]. A zero-width emote or a FrankerFaceZ modifier right after another emote joins
  /// that emote's [EmoteStack] instead, the way 7TV, BetterTTV and FrankerFaceZ draw them.
  void _addEmote(Emote emote) {
    final previous = splits.isEmpty ? null : splits.last;
    final layered = emote.flags & (EmoteFlags.overlay | EmoteFlags.modifier) != 0;
    if (!layered || (previous is! Emote && previous is! EmoteStack)) {
      splits.add(emote);
      return;
    }
    final stack = previous is EmoteStack ? previous : EmoteStack(previous as Emote);
    if (emote.flags & EmoteFlags.overlay != 0) {
      stack.overlays.add(emote);
    } else {
      stack.modifiers.add(emote);
    }
    splits.last = stack;
  }
}
