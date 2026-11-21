import 'dart:async';

import 'package:collection/collection.dart';

import '../../api/recentmessages/recentmessages.dart';
import '../../irc/message.dart' as irc;
import '../cache.dart';
import '../channel/channel.dart';
import '../channel/messages/channel_message_id.dart';
import '../connection/connection.dart';
import '../whispers/whisper_channel.dart';

/// The chat history of the channels: what the recent-messages service and the cache have from before the channel was
/// joined. The lines go through the same dispatch as live ones ([receive]), deduplicated by message id.
class ChatHistory {
  /// Where chat history comes from. Asks Settings → Chat history before each request.
  final RecentMessages recentMessages;

  /// The connection fetched history is inserted as coming from: the one that reads the chat.
  final Connection receiver;

  /// Where the history is kept between launches. Null in tests, then nothing is loaded or saved.
  final EmoteBadgeCache? cache;

  /// The joined channels.
  final List<Channel> Function() channels;

  /// Handles one parsed line as if [connection] had received it.
  final Future<void> Function(Connection connection, irc.Message message) receive;

  ChatHistory({
    required this.recentMessages,
    required this.receiver,
    this.cache,
    required this.channels,
    required this.receive,
  });

  // Building a ChannelMessageChat is expensive (emote parsing, regex, Hive
  // lookups). Deserialize history newest-first in chunks: the first (smaller)
  // chunk is the newest messages — the ones actually visible at the bottom of
  // the reverse chat list — so they appear almost immediately. Older chunks
  // are added above the viewport afterwards; with reverse:true the bottom
  // anchor doesn't move, so the chat doesn't jump. Yields between chunks keep
  // the UI responsive.
  static const int firstChunk = 30;
  static const int laterChunk = 40;

  /// Whether [message] from the recent-messages history is left out when inserting it: see [insertHistoryMessages].
  /// USERSTATE is about the own user at that time, so an old one would set [Channel.ownUserIsModerator] wrongly.
  static bool skippedInHistory(irc.Message message) =>
      const {'ROOMSTATE', 'NOTICE', 'USERSTATE'}.contains(message.command);

  Future<void> insertHistoryMessages(Connection connection, List<String> messages) async {
    // Parse once, preserving chronological (oldest->newest) order as delivered
    // by the recent-messages endpoint. Skip transient channel-state events:
    // ROOMSTATE, and NOTICE (slow/emote/follower-mode toggles etc.). These
    // describe past room state — replaying them is noise, and because NOTICEs
    // carry no `id` tag they also bypass the id-based dedup below, so each of
    // the three history passes (cached paint, lazy fetch, post-JOIN backfill)
    // would re-add them, producing the duplicate "now in slow mode / no longer
    // in slow mode" spam. USERNOTICE (subs/raids) is intentionally kept.
    final parsed = <irc.Message>[];
    for (final message in messages) {
      final irc.Message ircMessage;
      try {
        ircMessage = irc.Message.fromEvent(message);
      } on irc.InvalidIrcMessageException {
        continue;
      }
      if (skippedInHistory(ircMessage)) continue;
      parsed.add(ircMessage);
    }
    if (parsed.isEmpty) return;

    // History payloads are single-channel; find it from any chat message.
    final firstChatMessage = parsed.firstWhereOrNull(
      (m) => (m.command == 'PRIVMSG' || m.command == 'USERNOTICE') && m.parameters.isNotEmpty,
    );
    final bulkChannel = firstChatMessage == null
        ? null
        : channels().firstWhereOrNull((c) => c.name == firstChatMessage.parameters[0]);

    // Snapshot existing ids so we drop duplicates BEFORE building them (the
    // post-JOIN backfill mostly re-sends messages we already have).
    final existingIds =
        bulkChannel?.channelMessages.state.whereType<ChannelMessageId>().map((e) => e.id).toSet() ?? <String>{};

    // Walk from the end (newest) towards the start (oldest), one chunk per
    // iteration, emitting after each so the newest render first.
    var end = parsed.length;
    var first = true;
    while (end > 0) {
      final size = first ? firstChunk : laterChunk;
      first = false;
      final start = (end - size).clamp(0, end);
      final chunk = parsed.sublist(start, end);
      end = start;

      bulkChannel?.channelMessages.beginBulk();
      for (final ircMessage in chunk) {
        final id = ircMessageId(ircMessage);
        if (id != null && existingIds.contains(id)) continue;
        if (id != null) existingIds.add(id);
        unawaited(receive(connection, ircMessage));
      }
      bulkChannel?.channelMessages.endBulk();
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Lazily fetch recent-messages for [channel] (e.g. when its chat view is
  /// first opened). De-duplication in ChannelMessages.add drops anything
  /// already inserted from the cache.
  Future<void> ensureRecentMessages(Channel channel) async {
    // User is actively looking at this channel — make sure the throttled
    // JOIN scheduler picks it before any other queued channel.
    if (channel is WhisperChannel) return;
    channel.joinPriority = true;
    if (channel.recentMessagesFetched) return;
    channel.recentMessagesFetched = true;
    channel.recentMessagesEverFetched = true;
    if (!await _fetchAndInsertHistory(channel)) {
      channel.recentMessagesFetched = false;
    }
  }

  /// The receiver joined [channel]: queues the history cached on an earlier launch for its ROOMSTATE
  /// ([insertCached]), and fetches the history again if the user opened the channel before.
  void joined(Channel channel) {
    final channelLogin = channel.name.substring(1);
    // History cached on an earlier launch is only shown while chat history is on.
    channel.pendingHistoryCached = recentMessages.enabled()
        ? cache?.loadHistory(channelLogin) ?? const <String>[]
        : const <String>[];
    // If the user opened this channel before we managed to JOIN, pull
    // recent-messages again now that we are actually subscribed — that
    // closes the gap between our pre-JOIN snapshot and live PRIVMSGs.
    if (channel.recentMessagesEverFetched) {
      channel.recentMessagesFetched = true;
      unawaited(_backfillAfterJoin(channel));
    }
  }

  /// Shows the history of [channel] cached on an earlier launch, queued by [joined], once.
  Future<void> insertCached(Connection connection, Channel channel) async {
    final cachedHistory = channel.pendingHistoryCached;
    if (cachedHistory.isEmpty) return;
    channel.pendingHistoryCached = const [];
    await insertHistoryMessages(connection, cachedHistory);
  }

  /// Fetches the history of [viewed] again, in that order, e.g. after the receiver missed messages while the app was
  /// in the background. The backfill after the next JOIN runs again too.
  Future<void> refetch(List<Channel> viewed) async {
    await Future.wait(
      viewed.map((channel) {
        channel.joinBackfillDone = false;
        return _fetchAndInsertHistory(channel);
      }),
    );
  }

  /// Pull recent-messages again right after a successful JOIN to backfill
  /// anything that was sent while we were waiting for the JOIN ack — those
  /// PRIVMSGs are not delivered to us by Twitch until we are subscribed.
  Future<void> _backfillAfterJoin(Channel channel) async {
    if (channel.joinBackfillDone) return;
    channel.joinBackfillDone = true;
    if (!await _fetchAndInsertHistory(channel)) {
      channel.joinBackfillDone = false;
    }
  }

  // Fetch recent-messages for [channel], persist them, and insert into the
  // chat. Returns false on failure so callers can reset their latch.
  Future<bool> _fetchAndInsertHistory(Channel channel) async {
    final channelLogin = channel.name.substring(1);
    try {
      final list = await recentMessages.channel(channelLogin);
      // Chat history is turned off: nothing was requested. Report it like a failure, so the next fetch (opening the
      // chat, joining, reconnecting) tries again and picks the setting up if it was turned back on.
      if (list == null) return false;
      unawaited(cache?.saveHistory(channelLogin, list));
      await insertHistoryMessages(receiver, list);
      return true;
    } catch (_) {
      return false;
    }
  }
}
