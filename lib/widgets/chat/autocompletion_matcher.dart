import '../../data/emote.dart';
import '../../tmi/channel/channel.dart';
import '../../tmi/channel/channel_message.dart';
import '../../tmi/user.dart';

/// The chatters and emotes the composer suggests for the word being typed.
///
/// The composer rebuilds on every key typed and whenever the channel's state changes. Collecting the chatters from
/// all loaded messages and lowercasing the names of all emotes (a few thousand with the emojis) is done here only
/// when the messages or an emote list change, and the matches are remembered for the last search, so a rebuild for
/// anything else doesn't search again. The lists are cubit states, which are replaced on every change, so an
/// unchanged list is the identical object.
class AutocompletionMatcher {
  List<Emote>? _channelEmotes;
  List<Emote>? _globalEmotes;
  List<Emote>? _userEmotes;
  List<Emote> _emotes = const [];

  /// `:name:` of each of [_emotes], lowercase.
  List<String> _emoteKeys = const [];

  String? _emoteSearch;
  bool? _emoteNeedsColon;
  List<Emote> _emoteMatches = const [];

  List<ChannelMessage>? _messages;
  List<User> _chatters = const [];

  /// `@login` of each of [_chatters], lowercase.
  List<String> _chatterKeys = const [];

  String? _chatterSearch;
  bool? _chatterNeedsAt;
  List<User> _chatterMatches = const [];

  /// The emotes whose `:name:` contains [search] (lowercase), from the channel's emotes, the global ones and the
  /// user's Twitch emotes in that order. Those whose name starts with the search come first, each group in that
  /// order. With [needsColon] (Settings → autocomplete emotes only with `:`) a search without a leading `:`
  /// matches nothing.
  List<Emote> emotes({
    required List<Emote> channelEmotes,
    required List<Emote> globalEmotes,
    required List<Emote> userEmotes,
    required String search,
    required bool needsColon,
  }) {
    if (!identical(channelEmotes, _channelEmotes) ||
        !identical(globalEmotes, _globalEmotes) ||
        !identical(userEmotes, _userEmotes)) {
      _channelEmotes = channelEmotes;
      _globalEmotes = globalEmotes;
      _userEmotes = userEmotes;
      _emotes = [...channelEmotes, ...globalEmotes, ...userEmotes];
      _emoteKeys = [for (final emote in _emotes) ':${emote.name}:'.toLowerCase()];
      _emoteSearch = null;
    } else if (search == _emoteSearch && needsColon == _emoteNeedsColon) {
      return _emoteMatches;
    }
    _emoteSearch = search;
    _emoteNeedsColon = needsColon;
    if (needsColon && !search.startsWith(':')) return _emoteMatches = const [];
    // Emotes whose name starts with the search go first, then the ones that
    // only match further into the name.
    final prefix = search.startsWith(':') ? search : ':$search';
    final startingWith = <Emote>[];
    final containing = <Emote>[];
    for (var i = 0; i < _emotes.length; i++) {
      final key = _emoteKeys[i];
      if (key.startsWith(prefix)) {
        startingWith.add(_emotes[i]);
      } else if (key.contains(search)) {
        containing.add(_emotes[i]);
      }
    }
    return _emoteMatches = [...startingWith, ...containing];
  }

  /// The [Channel.chattersIn] [messages] whose `@login` contains [search] (lowercase), most recent first. With
  /// [needsAt] (Settings → autocomplete users only with `@`) a search without a leading `@` matches nobody.
  List<User> chatters({
    required List<ChannelMessage> messages,
    required String search,
    required bool needsAt,
  }) {
    if (!identical(messages, _messages)) {
      _messages = messages;
      _chatters = Channel.chattersIn(messages);
      _chatterKeys = [for (final chatter in _chatters) '@${chatter.login}'.toLowerCase()];
      _chatterSearch = null;
    } else if (search == _chatterSearch && needsAt == _chatterNeedsAt) {
      return _chatterMatches;
    }
    _chatterSearch = search;
    _chatterNeedsAt = needsAt;
    if (needsAt && !search.startsWith('@')) return _chatterMatches = const [];
    return _chatterMatches = [
      for (var i = 0; i < _chatters.length; i++)
        if (_chatterKeys[i].contains(search)) _chatters[i],
    ];
  }
}
