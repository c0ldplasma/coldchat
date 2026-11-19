import 'package:bloc/bloc.dart';

import '/tmi/channel/channel_state.dart';
import '../channel_message.dart';

class ChannelMessageStateChange extends ChannelMessage {
  Change<ChannelState> change;

  ChannelMessageStateChange({
    required this.change,
    required super.dateTime,
    super.channel,
  });
}
