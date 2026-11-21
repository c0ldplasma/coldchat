import 'dart:async';
import 'dart:math' show min;

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';

import '../channel/channel.dart';
import '../channel/channel_event.dart';
import '../channel/channel_state.dart';
import '../connection/connection.dart';
import '../connection/connection_state.dart';
import '../irc_log.dart';
import 'join_scheduler.dart';

/// Joins the channels on both connections, within Twitch's JOIN rate limit, the channel being looked at first.
///
/// Twitch IRC allows 20 JOINs per 10 seconds for normal users; a [JoinScheduler] keeps every pass within that (with a
/// margin) over a rolling window. The first pass after connecting may join a larger burst so the channels the user
/// cares about come up quickly; steady-state ticks stay conservative. The receiver and the transmitter each have their
/// own scheduler: the limit is per user, and the anonymous receiver isn't the account.
class ChannelJoiner {
  final Connection receiver;
  final Connection transmitter;

  /// The channels to join.
  final List<Channel> Function() channels;

  bool _firstJoinPass = true;
  final JoinScheduler _joins;
  bool _firstTransmitterJoinPass = true;
  final JoinScheduler _transmitterJoins;
  late final Timer _timer;

  /// Starts draining the join queue every 2 seconds. [receiverJoins] and [transmitterJoins] are replaceable for tests.
  ChannelJoiner({
    required this.receiver,
    required this.transmitter,
    required this.channels,
    JoinScheduler? receiverJoins,
    JoinScheduler? transmitterJoins,
  }) : _joins = receiverJoins ?? JoinScheduler(),
       _transmitterJoins = transmitterJoins ?? JoinScheduler() {
    // Drain the join queue on a timer as a steady-state fallback, but also
    // trigger an immediate pass as soon as the connection is established
    // (see receiverStateChanged) so we don't idle up to 2s
    // waiting for the first tick.
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => joinPending());
  }

  /// Stops the timer.
  void close() => _timer.cancel();

  /// Sends the JOINs that are due now instead of waiting for the next tick, e.g. after adding a channel. They still
  /// go through the rate limit.
  void joinPending() {
    _receiverJoinPass();
    _transmitterJoinPass();
  }

  /// Channels the user has explicitly requested (active chat view) or last had open sort first, so the channel
  /// actually being looked at is handled first.
  static int byJoinPriority(Channel a, Channel b) => a.joinPriority == b.joinPriority ? 0 : (a.joinPriority ? -1 : 1);

  void _receiverJoinPass() {
    if (receiver.state is! ConnectionConnected) return;
    // A JOIN that never got an echo (dropped by Twitch, or the channel doesn't exist) would leave the channel
    // connecting forever: queue it again, a limited number of times.
    for (final name in _joins.takeTimedOut()) {
      final channel = channels().firstWhereOrNull((channel) => channel.name == name);
      if (channel == null || channel.state is! ChannelConnecting) continue;
      final retry = _joins.canRetry(name);
      ircLog('receiver: JOIN $name timed out, ${retry ? 'retrying' : 'giving up until the next reconnect'}');
      if (retry) channel.add(ChannelPart());
    }
    final disconnected = channels().where((channel) => channel.state is ChannelDisconnected).toList();
    if (disconnected.isEmpty) return;
    final batchSize = min(_firstJoinPass ? 12 : 4, _joins.available);
    if (batchSize <= 0) return;
    disconnected.sort(byJoinPriority);
    _firstJoinPass = false;
    final channelsToJoin = disconnected.take(batchSize).toList();
    for (final channel in channelsToJoin) {
      channel.add(ChannelJoin(receiver, transmitter));
    }
    _joins.sent(channelsToJoin.map((e) => e.name));
    final names = channelsToJoin.map((e) => e.name).join(',');
    ircLog('receiver: JOIN $names');
    unawaited(receiver.send('JOIN $names'));
  }

  /// Joins the channels on the transmitter too, so it gets the account's USERSTATE there. Same rate limit and retries
  /// as the receiver, with its own [JoinScheduler] because the limit is per account.
  void _transmitterJoinPass() {
    if (transmitter.state is! ConnectionConnected) return;
    for (final name in _transmitterJoins.takeTimedOut()) {
      final retry = _transmitterJoins.canRetry(name);
      ircLog('transmitter: JOIN $name timed out, ${retry ? 'retrying' : 'giving up until the next reconnect'}');
    }
    final unjoined = channels()
        .where(
          (channel) =>
              !channel.transmitterJoin.state &&
              !_transmitterJoins.isPending(channel.name) &&
              _transmitterJoins.canRetry(channel.name),
        )
        .toList();
    if (unjoined.isEmpty) return;
    final batchSize = min(_firstTransmitterJoinPass ? 12 : 4, _transmitterJoins.available);
    if (batchSize <= 0) return;
    unjoined.sort(byJoinPriority);
    _firstTransmitterJoinPass = false;
    final channelsToJoin = unjoined.take(batchSize).map((e) => e.name).toList();
    _transmitterJoins.sent(channelsToJoin);
    final names = channelsToJoin.join(',');
    ircLog('transmitter: JOIN $names');
    unawaited(transmitter.send('JOIN $names'));
  }

  /// Twitch echoed the receiver's JOIN of [channelName].
  void receiverJoined(String channelName) => _joins.acknowledged(channelName);

  /// Twitch echoed the transmitter's JOIN of [channelName].
  void transmitterJoined(String channelName) => _transmitterJoins.acknowledged(channelName);

  /// The receiver's state changed: every channel has to be joined again (with fresh history), see [ChannelPart].
  void receiverStateChanged(Change<ConnectionState> change) {
    for (final channel in channels()) {
      channel.add(ChannelPart());
    }
    // On (re)connect, allow another larger join burst (still within the rate limit) and give every channel fresh
    // JOIN attempts.
    _firstJoinPass = true;
    _joins.reset();
    // Bloc calls onChange before it sets the new state, so the pass has to wait until the state is ConnectionConnected
    // (it used to return right away and leave the first JOINs to the next 2 s tick).
    if (change.nextState is ConnectionConnected) scheduleMicrotask(_receiverJoinPass);
  }

  /// The transmitter's state changed: it left every channel, and joins them again once it's connected.
  void transmitterStateChanged(Change<ConnectionState> change) {
    transmitterLeftChannels();
    // Bloc calls onChange before it sets the new state, so the pass has to wait until the state is ConnectionConnected.
    if (change.nextState is ConnectionConnected) scheduleMicrotask(_transmitterJoinPass);
  }

  /// The transmitter left every channel: it reconnected, switched accounts or logged out. Forgets the own user's
  /// state in each channel (e.g. moderator status of the previous account) until the next JOIN and USERSTATE.
  void transmitterLeftChannels() {
    for (final channel in channels()) {
      channel.transmitterParted();
    }
    _firstTransmitterJoinPass = true;
    _transmitterJoins.reset();
  }
}
