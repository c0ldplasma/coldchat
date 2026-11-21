import '../../../irc/message.dart' as irc;
import '../../user.dart';
import '../channel_message.dart';
import 'channel_message_id.dart';

/// A timeout, a ban or a cleared chat: an IRC `CLEARCHAT`.
class ChannelMessageBan extends ChannelMessage with ChannelMessageId {
  irc.Message message;
  User? user;

  /// How long [user] is timed out; null for a permanent ban and for a cleared chat.
  Duration? duration;

  ChannelMessageBan({
    required this.message,
    required super.dateTime,
    super.channel,
  }) {
    id = idOf(message) ?? 'clearchat-unstamped:${_unstamped++}';
    if (message.tags['target-user-id'] != null) {
      user = User(
        login: message.parameters[1],
        displayName: message.parameters[1],
        id: message.tags['target-user-id'],
      );
      final seconds = int.tryParse(message.tags['ban-duration'] ?? '');
      duration = seconds == null ? null : Duration(seconds: seconds);
    }
  }

  static int _unstamped = 0;

  /// The id a `CLEARCHAT` is told apart by, since Twitch gives it no `id` tag. The live line and its copy in the
  /// recent-messages history carry the same tags, so they get the same id and the chat shows the event once, while
  /// two timeouts of the same user differ in `tmi-sent-ts`. Twitch's own message ids are UUIDs and never contain a
  /// colon, so they can't collide with these.
  ///
  /// Null without a `tmi-sent-ts`, which Twitch always sends: such a line then gets an id of its own (see the
  /// constructor), so a duplicate may show twice but two different events never hide each other.
  static String? idOf(irc.Message message) {
    final sentAt = message.tags['tmi-sent-ts'];
    if (sentAt == null || sentAt.isEmpty) return null;
    final room = message.tags['room-id'] ?? (message.parameters.isEmpty ? '' : message.parameters[0]);
    return 'clearchat:$room:${message.tags['target-user-id'] ?? ''}:$sentAt';
  }
}
