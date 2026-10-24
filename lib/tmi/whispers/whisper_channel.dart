import 'dart:async';

import '/data/emote.dart';
import '/providers/emojis.dart';
import '../channel/channel.dart';

/// A whisper conversation with one user. It is a [Channel] so the chat view, composer and emote picker work
/// for it unchanged, but it is never joined over IRC: sending goes through [Whispers.send].
class WhisperChannel extends Channel {
  final String partnerId;
  String partnerLogin;
  String partnerDisplayName;

  /// Whether a whisper arrived since the conversation was last looked at.
  bool unread = false;

  Map<String, Emote>? _whisperEmoteLookup;
  final List<StreamSubscription> _whisperSubs = [];

  WhisperChannel({
    required super.client,
    required this.partnerId,
    required this.partnerLogin,
    required this.partnerDisplayName,
  }) : super(name: '@$partnerLogin') {
    _whisperSubs.addAll([
      client.globalEmotes.stream.listen((_) => _whisperEmoteLookup = null),
      client.twitchUserEmotes.stream.listen((_) => _whisperEmoteLookup = null),
    ]);
  }

  // Whispers carry no emote positions, so besides the global third-party emotes, Twitch emotes are recognized
  // by name from the ones this account can use.
  @override
  Map<String, Emote> get emoteLookup {
    final cached = _whisperEmoteLookup;
    if (cached != null) return cached;
    final map = <String, Emote>{};
    for (final e in client.globalEmotes.state) {
      if (e.provider is EmojiProvider) continue;
      map[e.code ?? e.name] = e;
    }
    for (final e in client.twitchUserEmotes.state) {
      map[e.code ?? e.name] = e;
    }
    return _whisperEmoteLookup = map;
  }

  @override
  Future<void> send(String message, {Map<String, String>? tags}) => client.whispers.send(this, message);

  @override
  Future<void> close() {
    for (final sub in _whisperSubs) {
      sub.cancel();
    }
    return super.close();
  }
}
