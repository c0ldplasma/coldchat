import 'package:flutter/foundation.dart';

import '../../data/emote.dart';

/// The emotes the picker and the composer's suggestions offer: all but those of the channels hidden in the picker
/// ([Emote.ownerId], see `SettingsRepository.hiddenEmoteChannels`). Chat messages still show hidden emotes, and they can
/// still be sent by typing their name.
///
/// The result is remembered: for the same list and the same hidden channels it is the identical list, and without a
/// hidden emote in it, the list given. The caches after it ([EmotePickerSectionsCache], `AutocompletionMatcher`) only
/// work again when a list is replaced.
class VisibleEmotes {
  List<Emote>? _emotes;
  Set<String> _hidden = const {};
  List<Emote> _visible = const [];

  List<Emote> of(List<Emote> emotes, Set<String> hiddenChannels) {
    if (identical(emotes, _emotes) && setEquals(hiddenChannels, _hidden)) return _visible;
    _emotes = emotes;
    _hidden = {...hiddenChannels};
    final noneHidden = hiddenChannels.isEmpty || !emotes.any((emote) => hiddenChannels.contains(emote.ownerId));
    return _visible = noneHidden
        ? emotes
        : [
            for (final emote in emotes)
              if (!hiddenChannels.contains(emote.ownerId)) emote,
          ];
  }
}
