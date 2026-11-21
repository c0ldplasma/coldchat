import 'dart:async';

import 'package:bloc/bloc.dart';

import '../connection/connection.dart';
import 'channel.dart';
import 'transmitter_join.dart';

/// [Channel.canSend] as state, for the composer's send button and hint: follows the [transmitter] connecting and
/// dropping and Twitch acknowledging its JOIN of the channel ([join]).
class CanSend extends Cubit<bool> {
  final Connection transmitter;
  final TransmitterJoin join;
  late final List<StreamSubscription<Object?>> _subscriptions;

  CanSend({required this.transmitter, required this.join})
    : super(Channel.canSendWith(transmitterConnected: transmitter.isConnected, transmitterJoined: join.state)) {
    _subscriptions = [
      transmitter.stream.listen((_) => _update()),
      join.stream.listen((_) => _update()),
    ];
  }

  void _update() {
    final canSend = Channel.canSendWith(transmitterConnected: transmitter.isConnected, transmitterJoined: join.state);
    // Only changes: a Cubit lets the first emit through even when it equals the initial state.
    if (!isClosed && canSend != state) emit(canSend);
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
