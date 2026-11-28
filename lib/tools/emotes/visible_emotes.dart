import 'package:flutter/foundation.dart';

import '../../data/emote.dart';
import 'emote_picker_sections.dart';

/// The emotes the picker and the composer's suggestions offer: all but those in sections hidden in the picker
/// ([emoteSectionKeyOf], see `SettingsRepository.hiddenEmoteSections`). Chat messages still show hidden emotes, and
/// they can still be sent by typing their name.
///
/// The result is remembered: for the same list and the same hidden sections it is the identical list, and without a
/// hidden emote in it, the list given. The caches after it ([EmotePickerSectionsCache], `AutocompletionMatcher`) only
/// work again when a list is replaced.
class VisibleEmotes {
  List<Emote>? _emotes;
  Set<String> _hidden = const {};
  List<Emote> _visible = const [];

  List<Emote> of(List<Emote> emotes, Set<String> hiddenSections) {
    if (identical(emotes, _emotes) && setEquals(hiddenSections, _hidden)) return _visible;
    _emotes = emotes;
    _hidden = {...hiddenSections};
    if (hiddenSections.isEmpty) return _visible = emotes;
    final visible = [
      for (final emote in emotes)
        if (!hiddenSections.contains(emoteSectionKeyOf(emote))) emote,
    ];
    return _visible = visible.length == emotes.length ? emotes : visible;
  }
}
