import '../../../irc/message.dart' as irc;
import '../channel_message.dart';

class ChannelMessageNotice extends ChannelMessage {
  irc.Message message;
  late String text;

  ChannelMessageNotice({
    required this.message,
    required super.dateTime,
    super.channel,
  }) {
    text = message.parameters.skip(1).join(':');
  }
}
