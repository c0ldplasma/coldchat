import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/channel_state.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:coldchat/tmi/connection/connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

TwitchAccount _account() => TwitchAccount(
  tokenData: TokenData(
    clientId: null,
    login: 'someone',
    scopes: const [],
    userId: null,
    expiresAt: null,
    accessToken: null,
  ),
  userData: null,
  cookies: null,
);

void main() {
  late Connection receiver;
  late Connection connected;
  late Connection disconnected;

  setUp(() async {
    receiver = Connection();
    connected = Connection();
    disconnected = Connection();
    connected.add(ConnectionEstablished(ConnectionConnected(_account())));
    await Future<void>.delayed(Duration.zero);
    expect(connected.isConnected, isTrue);
  });

  tearDown(() async {
    await receiver.close();
    await connected.close();
    await disconnected.close();
  });

  test('cannot send while the channel is not joined', () {
    expect(Channel.canSendIn(ChannelDisconnected()), isFalse);
  });

  test('cannot send while the JOIN is still pending', () {
    expect(Channel.canSendIn(ChannelConnecting(receiver: receiver, transmitter: connected)), isFalse);
  });

  test('can send once joined with the sending connection up', () {
    expect(Channel.canSendIn(ChannelConnected(receiver: receiver, transmitter: connected)), isTrue);
  });

  test('cannot send while the sending connection is down', () {
    expect(Channel.canSendIn(ChannelConnected(receiver: receiver, transmitter: disconnected)), isFalse);
  });

  test('suspended and banned channels still send, so Twitch can answer with its notice', () {
    expect(Channel.canSendIn(ChannelSuspended(receiver: receiver, transmitter: connected)), isTrue);
    expect(Channel.canSendIn(ChannelBanned(receiver: receiver, transmitter: connected)), isTrue);
  });
}
