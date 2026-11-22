import 'dart:async';

import 'package:bloc/bloc.dart';

import '../connection/connection.dart';
import 'channel.dart';
import 'transmitter_join.dart';

/// What the composer of a channel offers.
enum SendAvailability {
  /// No login to send with (logged out, or Twitch refused the login): the composer becomes a login button.
  needsLogin,

  /// Logged in, but the transmitter isn't connected or Twitch hasn't acknowledged its JOIN yet.
  connecting,

  /// A message sent now reaches the channel ([Channel.canSend]).
  ready,
}

/// [Channel.sendAvailability] as state, for the composer: follows the [transmitter] logging in and out, connecting
/// and dropping, and Twitch acknowledging its JOIN of the channel ([join]).
class CanSend extends Cubit<SendAvailability> {
  final Connection transmitter;
  final TransmitterJoin join;
  late final List<StreamSubscription<Object?>> _subscriptions;

  CanSend({required this.transmitter, required this.join})
    : super(Channel.sendAvailabilityWith(transmitter: transmitter.state, transmitterJoined: join.state)) {
    _subscriptions = [
      transmitter.stream.listen((_) => _update()),
      join.stream.listen((_) => _update()),
    ];
  }

  void _update() {
    final availability = Channel.sendAvailabilityWith(transmitter: transmitter.state, transmitterJoined: join.state);
    // Only changes: a Cubit lets the first emit through even when it equals the initial state.
    if (!isClosed && availability != state) emit(availability);
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
