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

  /// The emotes whose `:name:` contains [search] (as typed; matching ignores case), from the channel's emotes, the
  /// global ones and the user's Twitch emotes. Ranked like the channel search, adapted to emotes, whose names are
  /// case-sensitive:
  ///
  /// 1. the exact name, as typed (`Kappa` for "Kappa"),
  /// 2. the exact name in another case (`kappa` for "Kappa"),
  /// 3. names starting with the search: those matching its case first, then the shortest, then alphabetically,
  /// 4. names containing it further in.
  ///
  /// Ties keep the order channel, global, user. With [needsColon] (Settings → autocomplete emotes only with `:`) a
  /// search without a leading `:` matches nothing.
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
    final lower = search.toLowerCase();
    final prefix = lower.startsWith(':') ? lower : ':$lower';
    // The name the user means, without the `:` that only mark the start or end of a name.
    final name = search.replaceAll(RegExp(r'^:|:$'), '');
    final nameLower = name.toLowerCase();
    final matches = <({Emote emote, int tier, int index})>[];
    for (var i = 0; i < _emotes.length; i++) {
      final key = _emoteKeys[i];
      if (!key.contains(lower)) continue;
      final emote = _emotes[i];
      final tier = emote.name == name
          ? 0
          : emote.name.toLowerCase() == nameLower
          ? 1
          : key.startsWith(prefix)
          ? (emote.name.startsWith(name) ? 2 : 3)
          : 4;
      matches.add((emote: emote, tier: tier, index: i));
    }
    matches.sort((a, b) {
      final byTier = a.tier.compareTo(b.tier);
      if (byTier != 0) return byTier;
      if (a.tier == 2 || a.tier == 3) {
        final byLength = a.emote.name.length.compareTo(b.emote.name.length);
        if (byLength != 0) return byLength;
        final byName = a.emote.name.toLowerCase().compareTo(b.emote.name.toLowerCase());
        if (byName != 0) return byName;
      }
      return a.index.compareTo(b.index);
    });
    return _emoteMatches = [for (final match in matches) match.emote];
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
