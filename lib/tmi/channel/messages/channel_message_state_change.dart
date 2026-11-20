import 'package:bloc/bloc.dart';

import '../channel_message.dart';
import '../channel_state.dart';

class ChannelMessageStateChange extends ChannelMessage {
  Change<ChannelState> change;

  ChannelMessageStateChange({
    required this.change,
    required super.dateTime,
    super.channel,
  });
}
