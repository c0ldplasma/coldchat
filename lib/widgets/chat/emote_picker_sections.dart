import 'package:collection/collection.dart';

import '../../data/emote.dart';
import '../../providers/emojis.dart';

const twitchSection = 'Twitch';

/// A section of the emote picker: an emote category (e.g. an emoji group) or else a provider, with its emotes.
class EmoteSection {
  final String title;
  final List<Emote> emotes;

  const EmoteSection(this.title, this.emotes);
}

/// The emote picker's sections for one set of emote lists, and which of their emotes match a search.
///
/// With the emojis these are a few thousand emotes. Grouping them and lowercasing their names happens once here
/// instead of on every rebuild of the picker, which rebuilds with every key typed in the composer;
/// [EmotePickerSectionsCache] only makes a new one when an emote list changes.
class EmotePickerSections {
  /// Every section, in the picker's order: the emote sections in the order their emotes come in channel emotes,
  /// global emotes and the user's Twitch emotes, then the emoji sections. The Twitch section is always there, empty
  /// while Twitch's emotes load.
  final List<EmoteSection> sections;

  /// The lowercase name of each emote in [sections], at the same positions.
  final List<List<String>> _lowercaseNames;

  String? _search;
  List<EmoteSection>? _matching;

  EmotePickerSections._(this.sections, this._lowercaseNames);

  factory EmotePickerSections.group({
    required List<Emote> channelEmotes,
    required List<Emote> globalEmotes,
    required List<Emote> userEmotes,
  }) {
    final allEmotes = [...channelEmotes, ...globalEmotes, ...userEmotes];
    final emoteGroups = <String, List<Emote>>{};
    final emojiGroups = <String, List<Emote>>{};
    for (final providerGroup in groupBy(allEmotes, (emote) => emote.provider).entries) {
      // Emojis go after all Twitch/7TV/BTTV/FFZ sections.
      final target = providerGroup.key is EmojiProvider ? emojiGroups : emoteGroups;
      for (final category in groupBy(providerGroup.value, (emote) => emote.category).entries) {
        target.putIfAbsent(category.key ?? providerGroup.key.name, () => []).addAll(category.value);
      }
    }
    // There are always Twitch emotes, so keep their section in place with a
    // spinner while they load instead of having it pop in later.
    emoteGroups.putIfAbsent(twitchSection, () => []);
    final groups = {...emoteGroups, ...emojiGroups};
    return EmotePickerSections._(
      [for (final group in groups.entries) EmoteSection(group.key, group.value)],
      [
        for (final group in groups.values) [for (final emote in group) emote.name.toLowerCase()],
      ],
    );
  }

  /// The sections with an emote whose name contains [search] (lowercase), each with only those emotes. Without a
  /// search, all [sections], including those that are still empty (they show a spinner). The result for the last
  /// search is remembered, so rebuilding the picker with the same search doesn't filter again.
  List<EmoteSection> matching(String search) {
    if (search.isEmpty) return sections;
    final cached = _matching;
    if (cached != null && search == _search) return cached;
    final matching = <EmoteSection>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final names = _lowercaseNames[i];
      final emotes = [
        for (var j = 0; j < names.length; j++)
          if (names[j].contains(search)) section.emotes[j],
      ];
      if (emotes.isNotEmpty) matching.add(EmoteSection(section.title, emotes));
    }
    _search = search;
    return _matching = matching;
  }
}

/// Keeps the [EmotePickerSections] of the last emote lists it was given. The lists are cubit states, which are
/// replaced on every change, so an unchanged list is the identical object.
class EmotePickerSectionsCache {
  List<Emote>? _channelEmotes;
  List<Emote>? _globalEmotes;
  List<Emote>? _userEmotes;
  EmotePickerSections? _sections;

  EmotePickerSections sectionsFor({
    required List<Emote> channelEmotes,
    required List<Emote> globalEmotes,
    required List<Emote> userEmotes,
  }) {
    final cached = _sections;
    if (cached != null &&
        identical(channelEmotes, _channelEmotes) &&
        identical(globalEmotes, _globalEmotes) &&
        identical(userEmotes, _userEmotes)) {
      return cached;
    }
    _channelEmotes = channelEmotes;
    _globalEmotes = globalEmotes;
    _userEmotes = userEmotes;
    return _sections = EmotePickerSections.group(
      channelEmotes: channelEmotes,
      globalEmotes: globalEmotes,
      userEmotes: userEmotes,
    );
  }
}
