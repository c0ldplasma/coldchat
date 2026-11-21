import 'package:bloc/bloc.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/channel_event.dart';
import 'package:coldchat/tmi/channel/channel_state.dart';
import 'package:coldchat/tmi/client/channel_joiner.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/client/join_scheduler.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_client.dart';

/// A connection that records what it sends, in whatever [state] the test sets.
class _FakeConnection implements Connection {
  @override
  ConnectionState state = ConnectionDisconnected();

  final List<String> sent = [];

  @override
  Future<void> send(String message) async => sent.add(message);

  void goOnline() => state = ConnectionConnected(Client.anonymousAccount(), nick: 'justinfan1');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeConnection receiver;
  late _FakeConnection transmitter;
  late List<Channel> channels;
  late DateTime now;

  setUp(() {
    receiver = _FakeConnection();
    transmitter = _FakeConnection();
    channels = [];
    now = DateTime(2026);
  });

  void addChannels(Iterable<String> names) {
    for (final name in names) {
      final channel = Channel(client: FakeClient(), name: name);
      addTearDown(channel.close);
      channels.add(channel);
    }
  }

  ChannelJoiner joiner() {
    final joiner = ChannelJoiner(
      receiver: receiver,
      transmitter: transmitter,
      channels: () => channels,
      receiverJoins: JoinScheduler(now: () => now),
      transmitterJoins: JoinScheduler(now: () => now),
    );
    addTearDown(joiner.close);
    return joiner;
  }

  /// Lets the channels handle the events they were sent.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('joins nothing while the connections are down', () {
    addChannels(['#ronni']);
    joiner().joinPending();

    expect(receiver.sent, isEmpty);
    expect(transmitter.sent, isEmpty);
  });

  test('joins the priority channel first, up to 12 at first and then 4 per pass', () async {
    addChannels([for (var i = 0; i < 20; i++) '#c$i']);
    channels[15].joinPriority = true;
    receiver.goOnline();
    final j = joiner();

    j.joinPending();
    await settle();
    expect(receiver.sent, [
      'JOIN #c15,${[for (var i = 0; i < 11; i++) '#c$i'].join(',')}',
    ]);
    expect(channels[15].state, isA<ChannelConnecting>());

    j.joinPending();
    await settle();
    expect(receiver.sent.last, 'JOIN #c11,#c12,#c13,#c14');
  });

  test('stays within the rate limit', () async {
    addChannels([for (var i = 0; i < 30; i++) '#c$i']);
    receiver.goOnline();
    final j = joiner();

    for (var pass = 0; pass < 5; pass++) {
      j.joinPending();
      await settle();
    }

    // 12 + 4, then only 2 more fit into the 18 per 10 seconds.
    expect(receiver.sent.map((line) => line.split(',').length), [12, 4, 2]);

    now = now.add(const Duration(seconds: 11));
    j.joinPending();
    expect(receiver.sent.last.split(','), hasLength(4));
  });

  test('both connections get their own passes, the transmitter only once it has joined', () async {
    addChannels(['#ronni', '#forsen']);
    channels[1].joinPriority = true;
    receiver.goOnline();
    transmitter.goOnline();
    final j = joiner();

    j.joinPending();
    await settle();
    expect(receiver.sent, ['JOIN #forsen,#ronni']);
    expect(transmitter.sent, ['JOIN #forsen,#ronni']);

    // The transmitter's JOINs are pending until echoed; the receiver's channels are connecting.
    j.joinPending();
    expect(receiver.sent, hasLength(1));
    expect(transmitter.sent, hasLength(1));

    j.transmitterJoined('#ronni');
    channels[0].transmitterJoin.joined();
    j.transmitterJoined('#forsen');
    channels[1].transmitterJoin.joined();
    j.joinPending();
    expect(transmitter.sent, hasLength(1));
  });

  test('channels the transmitter left are joined again', () async {
    addChannels(['#ronni', '#forsen']);
    transmitter.goOnline();
    final j = joiner();
    j.joinPending();
    for (final channel in channels) {
      j.transmitterJoined(channel.name);
      channel.transmitterJoin.joined();
    }

    j.transmitterLeftChannels();

    expect(channels.map((channel) => channel.transmitterJoin.state), [false, false]);
    j.joinPending();
    expect(transmitter.sent, ['JOIN #ronni,#forsen', 'JOIN #ronni,#forsen']);
    expect(receiver.sent, isEmpty);
  });

  test('the transmitter joins as soon as it is connected', () async {
    addChannels(['#ronni']);
    final j = joiner();
    transmitter.goOnline();

    j.transmitterStateChanged(Change(currentState: ConnectionDisconnected(), nextState: transmitter.state));
    expect(transmitter.sent, isEmpty);
    await settle();

    expect(transmitter.sent, ['JOIN #ronni']);
  });

  test('a new receiver connection parts every channel and joins them again right away', () async {
    addChannels(['#ronni', '#forsen']);
    receiver.goOnline();
    final j = joiner();
    j.joinPending();
    await settle();
    j.receiverJoined('#ronni');
    channels[0].add(ChannelConnect());
    await settle();
    expect(channels[0].state, isA<ChannelConnected>());

    j.receiverStateChanged(Change(currentState: ConnectionDisconnected(), nextState: receiver.state));
    await settle();

    expect(receiver.sent, ['JOIN #ronni,#forsen', 'JOIN #ronni,#forsen']);
    expect(channels.map((channel) => channel.state), everyElement(isA<ChannelConnecting>()));
  });

  /// Runs a join pass every 2 seconds for [duration] and returns when each receiver JOIN of [channel] was sent,
  /// relative to the start.
  Future<List<int>> joinTimes(ChannelJoiner j, _FakeConnection connection, String channel, Duration duration) async {
    final start = now;
    final times = <int>[];
    while (now.difference(start) < duration) {
      final before = connection.sent.length;
      j.joinPending();
      await settle();
      if (connection.sent.skip(before).any((line) => line.substring(5).split(',').contains(channel))) {
        times.add(now.difference(start).inSeconds);
      }
      now = now.add(const Duration(seconds: 2));
    }
    return times;
  }

  test('a JOIN without an echo is retried at once 3 times, then after a growing delay', () async {
    addChannels(['#gone']);
    receiver.goOnline();
    final j = joiner();

    final times = await joinTimes(j, receiver, '#gone', const Duration(minutes: 10));

    // 20 s timeout, the part and the JOIN on the next passes; then 30 s, 60 s, 120 s and 240 s on top of the timeout.
    expect(times, [0, 22, 44, 96, 178, 320, 582]);
    expect(channels.single.state, isA<ChannelConnecting>(), reason: 'shown as connecting while it waits');
  });

  test('a JOIN that is answered late still connects the channel and resets the retries', () async {
    addChannels(['#slow']);
    receiver.goOnline();
    final j = joiner();
    await joinTimes(j, receiver, '#slow', const Duration(seconds: 70));
    expect(receiver.sent, hasLength(3));

    j.receiverJoined('#slow');
    channels.single.add(ChannelConnect());
    await settle();
    final times = await joinTimes(j, receiver, '#slow', const Duration(minutes: 5));

    expect(times, isEmpty);
    expect(channels.single.state, isA<ChannelConnected>());
  });

  test('the transmitter retries an unanswered JOIN the same way', () async {
    addChannels(['#gone']);
    transmitter.goOnline();
    final j = joiner();

    final times = await joinTimes(j, transmitter, '#gone', const Duration(minutes: 10));

    // The transmitter doesn't part first, so each JOIN goes out on the pass right after the delay.
    expect(times, [0, 20, 40, 90, 170, 310, 570]);
  });

  test('a channel Twitch says is suspended is not retried', () async {
    addChannels(['#suspended']);
    receiver.goOnline();
    transmitter.goOnline();
    final j = joiner();
    j.joinPending();
    await settle();
    channels.single.add(ChannelSuspend());
    await settle();
    expect(channels.single.state, isA<ChannelSuspended>());

    await joinTimes(j, receiver, '#suspended', const Duration(minutes: 10));

    expect(receiver.sent, ['JOIN #suspended']);
    expect(transmitter.sent, ['JOIN #suspended']);
  });

  test('retries stay within the rate limit', () async {
    addChannels([for (var i = 0; i < 40; i++) '#c$i']);
    receiver.goOnline();
    transmitter.goOnline();
    final j = joiner();
    final receiverSentAt = <DateTime>[];
    final transmitterSentAt = <DateTime>[];

    final start = now;
    while (now.difference(start) < const Duration(minutes: 10)) {
      final receiverBefore = receiver.sent.length;
      final transmitterBefore = transmitter.sent.length;
      j.joinPending();
      await settle();
      for (final line in receiver.sent.skip(receiverBefore)) {
        receiverSentAt.addAll(List.filled(line.split(',').length, now));
      }
      for (final line in transmitter.sent.skip(transmitterBefore)) {
        transmitterSentAt.addAll(List.filled(line.split(',').length, now));
      }
      now = now.add(const Duration(seconds: 2));
    }

    expect(receiverSentAt.length, greaterThan(6 * 40), reason: 'every channel is still being retried');
    for (final sentAt in [receiverSentAt, transmitterSentAt]) {
      for (final t in sentAt) {
        final inWindow = sentAt.where((s) => !s.isBefore(t) && s.difference(t) < const Duration(seconds: 10));
        expect(inWindow.length, lessThanOrEqualTo(18));
      }
    }
  });

  test('passes run every 2 seconds until closed', () {
    fakeAsync((async) {
      addChannels(['#ronni']);
      receiver.goOnline();
      final j = joiner();

      async.elapse(const Duration(milliseconds: 1900));
      expect(receiver.sent, isEmpty);
      async.elapse(const Duration(milliseconds: 100));
      expect(receiver.sent, ['JOIN #ronni']);

      j.close();
      channels.single.add(ChannelPart());
      async.elapse(const Duration(seconds: 10));
      expect(receiver.sent, hasLength(1));
    });
  });
}
