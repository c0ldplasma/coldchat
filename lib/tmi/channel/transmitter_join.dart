import 'package:bloc/bloc.dart';

/// Whether the transmitter (the connection logged in as the active account) has joined a channel: Twitch echoed its
/// JOIN. Only then do messages sent there arrive, and the transmitter receives the channel's USERSTATE.
///
/// Separate from the [Channel]'s own state, which is about the anonymous receiver that reads the chat, so switching
/// accounts doesn't touch the chat that is being read.
class TransmitterJoin extends Cubit<bool> {
  TransmitterJoin() : super(false);

  void joined() => emit(true);

  void parted() => emit(false);
}
