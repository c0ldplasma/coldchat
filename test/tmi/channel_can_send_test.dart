import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/tmi/channel/can_send.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/transmitter_join.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:coldchat/tmi/connection/connection_state.dart' as tmi;
import 'package:flutter_test/flutter_test.dart';

final _account = TwitchAccount(
  tokenData: TokenData(
    clientId: null,
    login: 'ronni',
    scopes: const [],
    userId: '1337',
    expiresAt: null,
    accessToken: 'token',
  ),
  userData: null,
  cookies: null,
);

void main() {
  test('cannot send while the transmitter has not joined the channel', () {
    expect(Channel.canSendWith(transmitterConnected: true, transmitterJoined: false), isFalse);
  });

  test('can send once the transmitter is connected and joined', () {
    expect(Channel.canSendWith(transmitterConnected: true, transmitterJoined: true), isTrue);
  });

  test('cannot send while the transmitter is down', () {
    expect(Channel.canSendWith(transmitterConnected: false, transmitterJoined: true), isFalse);
    expect(Channel.canSendWith(transmitterConnected: false, transmitterJoined: false), isFalse);
  });

  test('TransmitterJoin starts parted and reports joins and parts', () async {
    final join = TransmitterJoin();
    addTearDown(join.close);
    final states = <bool>[];
    final subscription = join.stream.listen(states.add);
    addTearDown(subscription.cancel);

    expect(join.state, isFalse);
    join.joined();
    join.parted();
    await Future<void>.delayed(Duration.zero);

    expect(states, [true, false]);
  });

  group('CanSend', () {
    late Connection transmitter;
    late TransmitterJoin join;
    late CanSend canSend;
    late List<bool> states;

    setUp(() {
      transmitter = Connection(name: 'transmitter');
      join = TransmitterJoin();
      canSend = CanSend(transmitter: transmitter, join: join);
      states = [];
      final subscription = canSend.stream.listen(states.add);
      addTearDown(() async {
        await subscription.cancel();
        await canSend.close();
        await join.close();
        await transmitter.close();
      });
    });

    Future<void> connect() async {
      transmitter.add(ConnectionEstablished(tmi.ConnectionConnected(_account)));
      await transmitter.stream.firstWhere((state) => state is tmi.ConnectionConnected);
    }

    test('starts from the transmitter and the JOIN as they are', () async {
      expect(canSend.state, isFalse);
      await connect();
      join.joined();
      await Future<void>.delayed(Duration.zero);
      final later = CanSend(transmitter: transmitter, join: join);
      addTearDown(later.close);
      expect(later.state, isTrue);
    });

    test('becomes true once the transmitter is connected and its JOIN acknowledged', () async {
      await connect();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, isFalse);

      join.joined();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, isTrue);
      expect(states, [true]);
    });

    test('becomes false when the transmitter drops or parts, and true again after the next JOIN', () async {
      join.joined();
      await connect();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, isTrue);

      transmitter.add(ConnectionDisconnect());
      await transmitter.stream.firstWhere((state) => state is tmi.ConnectionDisconnected);
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, isFalse);

      await connect();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, isTrue);

      join.parted();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, isFalse);
      expect(states, [true, false, true, false]);
    });
  });
}
