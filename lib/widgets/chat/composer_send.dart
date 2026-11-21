/// What sending the composer's text does, decided by [composerSendFor].
sealed class ComposerSend {
  const ComposerSend();
}

/// `/w <login>` without a message: open the conversation with [login].
final class OpenWhisper extends ComposerSend {
  final String login;

  const OpenWhisper(this.login);
}

/// `/w <login> <message>`: whisper [message] to [login].
final class SendWhisper extends ComposerSend {
  final String login;
  final String message;

  const SendWhisper(this.login, this.message);
}

/// Text typed into a whisper conversation: send it there.
final class SendInWhisperChannel extends ComposerSend {
  const SendInWhisperChannel();
}

/// A chat message for the channel.
final class SendToChannel extends ComposerSend {
  const SendToChannel();
}

/// The channel isn't joined yet (e.g. the JOIN still waits for the rate limit after an account switch): Twitch would
/// drop the message, so it stays in the composer.
final class NotConnected extends ComposerSend {
  const NotConnected();
}

// `/w <user> [message]`, as on Twitch. Twitch no longer accepts it over IRC, so it goes through Helix.
final RegExp _whisperCommand = RegExp(r'^/(?:w|whisper)\s+@?(\S+)(?:\s+(.*))?$', dotAll: true);

/// The `/w` or `/whisper` command in [text], ignoring surrounding whitespace: the login without `@` and the trimmed
/// message, empty when there is none. Null when [text] isn't such a command.
({String login, String message})? parseWhisperCommand(String text) {
  final match = _whisperCommand.firstMatch(text.trim());
  if (match == null) return null;
  return (login: match.group(1)!, message: match.group(2)?.trim() ?? '');
}

/// What sending [text] does: a whisper command wins everywhere, a whisper conversation sends anything else as a
/// whisper, and a channel sends only when [canSend].
ComposerSend composerSendFor(String text, {required bool isWhisperChannel, required bool canSend}) {
  final whisper = parseWhisperCommand(text);
  if (whisper != null) {
    return whisper.message.isEmpty ? OpenWhisper(whisper.login) : SendWhisper(whisper.login, whisper.message);
  }
  if (isWhisperChannel) return const SendInWhisperChannel();
  if (!canSend) return const NotConnected();
  return const SendToChannel();
}
