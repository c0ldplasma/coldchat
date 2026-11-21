import '../../../irc/message.dart' as irc;
import 'channel_message_ban.dart';

mixin ChannelMessageId {
  late String id;
}

/// The [ChannelMessageId.id] the message built from [message] gets, or null if it has none (it's then never
/// deduplicated). Used to skip history lines the chat already shows before building them.
String? ircMessageId(irc.Message message) =>
    message.command == 'CLEARCHAT' ? ChannelMessageBan.idOf(message) : message.tags['id'];
