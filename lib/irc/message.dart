class Message {
  String raw;
  Map<String, String> tags;
  String? prefix;
  String command;
  List<String> parameters;

  Message({
    required this.raw,
    required this.tags,
    required this.prefix,
    required this.command,
    required this.parameters,
  });

  /// Undoes IRCv3's tag value escaping (https://ircv3.net/specs/extensions/message-tags#escaping-values): Twitch
  /// sends e.g. a space in `system-msg` or a reply's quoted text as `\s` and a semicolon as `\:`.
  static String unescapeTagValue(String value) {
    if (!value.contains('\\')) return value;
    final out = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char != '\\') {
        out.write(char);
        continue;
      }
      // A lone backslash at the end is dropped.
      if (++i == value.length) break;
      out.write(switch (value[i]) {
        ':' => ';',
        's' => ' ',
        'r' => '\r',
        'n' => '\n',
        final other => other,
      });
    }
    return out.toString();
  }

  /// The command of [line] without parsing the rest, e.g. its tags: the same one [Message.fromEvent] would find. Null
  /// when [Message.fromEvent] would find none and throw.
  static String? commandOf(String line) {
    var start = 0;
    if (line.startsWith('@')) {
      final space = line.indexOf(' ');
      if (space < 0) return null;
      start = space + 1;
    }
    if (line.startsWith(':', start)) {
      final space = line.indexOf(' ', start);
      if (space < 0) return null;
      start = space + 1;
    }
    final end = line.indexOf(' ', start);
    final command = line.substring(start, end < 0 ? line.length : end);
    return command.isEmpty ? null : command;
  }

  factory Message.fromEvent(String event) {
    final parts = event.split(' ');
    // if (parts.length < 2) {
    //   throw 'invalid irc message: $event';
    // }

    var tags = <String, String>{};
    if (parts.isNotEmpty && parts.first.startsWith('@')) {
      tags = <String, String>{
        for (final tag in parts.first.substring(1).split(';'))
          if (tag.contains('=')) tag.split('=').first: unescapeTagValue(tag.split('=').skip(1).join('=')),
      };

      parts.removeAt(0);
    }

    String? prefix;
    if (parts.isNotEmpty && parts.first.startsWith(':')) {
      prefix = parts.first.substring(1);
      parts.removeAt(0);
    }

    // An empty line splits into [''], hence the check for an empty command too.
    if (parts.isEmpty || parts.first.isEmpty) {
      throw InvalidIrcMessageException('invalid irc message: $event');
    }

    final command = parts.first;
    parts.removeAt(0);

    final parameters = <String>[];
    for (int i = 0; i < parts.length; ++i) {
      final part = parts[i];
      if (part.startsWith(':')) {
        parameters.add(parts.skip(i).join(' ').substring(1));
        break;
      } else {
        parameters.add(part);
      }
    }

    return Message(
      raw: event,
      tags: tags,
      prefix: prefix,
      command: command,
      parameters: parameters,
    );
  }
}

/// Thrown by [Message.fromEvent] for a line that isn't an IRC message.
///
/// [toString] is just the message, so logs show the same text a plain string did.
class InvalidIrcMessageException implements Exception {
  final String message;

  const InvalidIrcMessageException(this.message);

  @override
  String toString() => message;
}
