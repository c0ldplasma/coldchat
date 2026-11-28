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

  group('sendAvailabilityWith', () {
    SendAvailability availability(tmi.ConnectionState transmitter, {bool joined = true}) =>
        Channel.sendAvailabilityWith(transmitter: transmitter, transmitterJoined: joined);

    test('needs a login while logged out: logging out leaves the transmitter disconnected', () {
      expect(availability(tmi.ConnectionDisconnected()), SendAvailability.needsLogin);
      expect(availability(tmi.ConnectionDisconnected(), joined: false), SendAvailability.needsLogin);
    });

    test('needs a login when Twitch refused it', () {
      expect(availability(tmi.ConnectionInvalidCredentials(_account)), SendAvailability.needsLogin);
    });

    test('is connecting while the transmitter connects, reconnects or has not joined yet', () {
      expect(availability(tmi.ConnectionConnecting(_account)), SendAvailability.connecting);
      expect(availability(tmi.ConnectionReconnecting(_account)), SendAvailability.connecting);
      expect(availability(tmi.ConnectionConnected(_account), joined: false), SendAvailability.connecting);
    });

    test('is ready once connected and joined', () {
      expect(availability(tmi.ConnectionConnected(_account)), SendAvailability.ready);
    });
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
    late List<SendAvailability> states;

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
      expect(canSend.state, SendAvailability.needsLogin);
      await connect();
      join.joined();
      await Future<void>.delayed(Duration.zero);
      final later = CanSend(transmitter: transmitter, join: join);
      addTearDown(later.close);
      expect(later.state, SendAvailability.ready);
    });

    test('becomes ready once the transmitter is connected and its JOIN acknowledged', () async {
      await connect();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, SendAvailability.connecting);

      join.joined();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, SendAvailability.ready);
      expect(states, [SendAvailability.connecting, SendAvailability.ready]);
    });

    test('needs a login after logging out, is ready again after the next login and JOIN', () async {
      join.joined();
      await connect();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, SendAvailability.ready);

      transmitter.add(ConnectionDisconnect());
      await transmitter.stream.firstWhere((state) => state is tmi.ConnectionDisconnected);
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, SendAvailability.needsLogin);

      await connect();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, SendAvailability.ready);

      join.parted();
      await Future<void>.delayed(Duration.zero);
      expect(canSend.state, SendAvailability.connecting);
      expect(states, [
        SendAvailability.ready,
        SendAvailability.needsLogin,
        SendAvailability.ready,
        SendAvailability.connecting,
      ]);
    });
  });

  test('only a channel without a login shows the login button; a whisper conversation keeps its field', () {
    expect(composerNeedsLogin(SendAvailability.needsLogin, isWhisper: false), isTrue);
    expect(composerNeedsLogin(SendAvailability.connecting, isWhisper: false), isFalse);
    expect(composerNeedsLogin(SendAvailability.ready, isWhisper: false), isFalse);
    expect(composerNeedsLogin(SendAvailability.needsLogin, isWhisper: true), isFalse);
  });
}
