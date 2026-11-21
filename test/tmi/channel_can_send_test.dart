import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/transmitter_join.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
