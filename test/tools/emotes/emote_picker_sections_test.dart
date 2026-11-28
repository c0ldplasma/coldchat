import 'package:coldchat/api/emojis/emoji_data.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/sources/emoji_source.dart';
import 'package:coldchat/tools/emotes/emote_picker_sections.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../api/fake_api.dart';

class _Source extends ChatSource {
  @override
  final String name;

  _Source(this.name);

  @override
  String? get description => null;
}

final _twitch = _Source('Twitch');
final _sevenTv = _Source('7TV');
final _bttv = _Source('BetterTTV');
final _emoji = EmojiSource(EmojiDataApi(offlineApi()));

Emote _emote(String name, ChatSource source, {String? category, String? categoryIcon}) => Emote(
  id: name,
  name: name,
  mipmap: ['https://example.com/$name'],
  source: source,
  category: category,
  categoryIcon: categoryIcon,
);

/// The titles of [sections] with the names of their emotes.
Map<String, List<String>> _titles(List<EmoteSection> sections) => {
  for (final section in sections) section.title: [for (final emote in section.emotes) emote.name],
};

void main() {
  group('EmotePickerSections.group', () {
    test('puts emote sections in the order their emotes come, then the emoji sections', () {
      final sections = EmotePickerSections.group(
        channelEmotes: [_emote('peepoHappy', _sevenTv), _emote('catJAM', _bttv), _emote('EZ', _sevenTv)],
        globalEmotes: [
          _emote('grinning', _emoji, category: 'Smileys & Emotion'),
          _emote('Kappa', _twitch),
          _emote('dog', _emoji, category: 'Animals & Nature'),
          _emote('smile', _emoji, category: 'Smileys & Emotion'),
        ],
        userEmotes: [_emote('ronniHi', _twitch)],
      );

      expect(_titles(sections.sections), {
        '7TV': ['peepoHappy', 'EZ'],
        'BetterTTV': ['catJAM'],
        'Twitch': ['Kappa', 'ronniHi'],
        'Smileys & Emotion': ['grinning', 'smile'],
        'Animals & Nature': ['dog'],
      });
      expect(sections.sections.map((section) => section.title), [
        '7TV',
        'BetterTTV',
        'Twitch',
        'Smileys & Emotion',
        'Animals & Nature',
      ]);
    });

    test('keeps an empty Twitch section after the other emote sections while Twitch emotes load', () {
      final sections = EmotePickerSections.group(
        channelEmotes: [_emote('EZ', _sevenTv)],
        globalEmotes: [_emote('grinning', _emoji, category: 'Smileys & Emotion')],
        userEmotes: const [],
      );

      expect(_titles(sections.sections), {
        '7TV': ['EZ'],
        'Twitch': <String>[],
        'Smileys & Emotion': ['grinning'],
      });
    });

    test('names a section by the category when the emote has one', () {
      final sections = EmotePickerSections.group(
        channelEmotes: [_emote('ronniHi', _twitch, category: 'ronni')],
        globalEmotes: [_emote('Kappa', _twitch)],
        userEmotes: const [],
      );

      expect(_titles(sections.sections), {
        'ronni': ['ronniHi'],
        'Twitch': ['Kappa'],
      });
    });

    test("gives each channel's sub emotes a section with its badge, also when searching", () {
      final sections = EmotePickerSections.group(
        channelEmotes: const [],
        globalEmotes: const [],
        userEmotes: [
          _emote('Kappa', _twitch),
          _emote('ronniHi', _twitch, category: 'Ronni', categoryIcon: 'https://example.com/ronni-sub'),
          _emote('ronniBye', _twitch, category: 'Ronni', categoryIcon: 'https://example.com/ronni-sub'),
          _emote('forsenE', _twitch, category: 'forsen'),
        ],
      );

      expect(_titles(sections.sections), {
        'Twitch': ['Kappa'],
        'Ronni': ['ronniHi', 'ronniBye'],
        'forsen': ['forsenE'],
      });
      expect(
        [for (final section in sections.sections) section.iconUrl],
        [
          null,
          'https://example.com/ronni-sub',
          null,
        ],
      );
      expect(sections.matching('bye').single.iconUrl, 'https://example.com/ronni-sub');
    });
  });

  group('EmotePickerSections.matching', () {
    final sections = EmotePickerSections.group(
      channelEmotes: [_emote('peepoHappy', _sevenTv), _emote('EZ', _sevenTv)],
      globalEmotes: [
        _emote('grinning', _emoji, category: 'Smileys & Emotion'),
        _emote('happy', _emoji, category: 'Smileys & Emotion'),
      ],
      userEmotes: const [],
    );

    test('returns every section, empty ones too, without a search', () {
      expect(_titles(sections.matching('')), {
        '7TV': ['peepoHappy', 'EZ'],
        'Twitch': <String>[],
        'Smileys & Emotion': ['grinning', 'happy'],
      });
    });

    test('keeps only the emotes whose name contains the search, ignoring case, and drops sections without one', () {
      expect(_titles(sections.matching('happy')), {
        '7TV': ['peepoHappy'],
        'Smileys & Emotion': ['happy'],
      });
      expect(_titles(sections.matching('ez')), {
        '7TV': ['EZ'],
      });
      expect(sections.matching('nothing'), isEmpty);
    });

    test('filters again only when the search changes', () {
      final first = sections.matching('happy');
      expect(sections.matching('happy'), same(first));
      final other = sections.matching('ez');
      expect(other, isNot(same(first)));
      expect(_titles(sections.matching('happy')), _titles(first));
    });
  });

  group('EmotePickerSectionsCache', () {
    test('groups again only when an emote list is replaced', () {
      final cache = EmotePickerSectionsCache();
      final channelEmotes = [_emote('EZ', _sevenTv)];
      final globalEmotes = [_emote('Kappa', _twitch)];
      final userEmotes = <Emote>[];

      final first = cache.sectionsFor(channelEmotes: channelEmotes, globalEmotes: globalEmotes, userEmotes: userEmotes);
      expect(
        cache.sectionsFor(channelEmotes: channelEmotes, globalEmotes: globalEmotes, userEmotes: userEmotes),
        same(first),
      );

      // Newly loaded emotes come as a new list, like a cubit emits them.
      final moreUserEmotes = [_emote('ronniHi', _twitch)];
      final second = cache.sectionsFor(
        channelEmotes: channelEmotes,
        globalEmotes: globalEmotes,
        userEmotes: moreUserEmotes,
      );
      expect(second, isNot(same(first)));
      expect(_titles(second.sections), {
        '7TV': ['EZ'],
        'Twitch': ['Kappa', 'ronniHi'],
      });

      final moreChannelEmotes = [...channelEmotes, _emote('catJAM', _bttv)];
      final third = cache.sectionsFor(
        channelEmotes: moreChannelEmotes,
        globalEmotes: globalEmotes,
        userEmotes: moreUserEmotes,
      );
      expect(third, isNot(same(second)));
      expect(_titles(third.matching('cat')), {
        'BetterTTV': ['catJAM'],
      });
    });
  });

  group('currentSectionIndex', () {
    test('is the last section whose start has reached the top', () {
      const starts = [60.0, 400.0, 900.0];
      expect(currentSectionIndex(starts, 0.0), 0, reason: 'above the first section, at the search field');
      expect(currentSectionIndex(starts, 60.0), 0);
      expect(currentSectionIndex(starts, 398.0), 0);
      expect(currentSectionIndex(starts, 400.0), 1);
      expect(currentSectionIndex(starts, 5000.0), 2);
    });

    test('takes a section scrolled to with a rounding error as reached', () {
      expect(currentSectionIndex([0.0, 400.0], 399.5), 1);
    });

    test('is null without sections', () {
      expect(currentSectionIndex(const [], 100.0), isNull);
    });
  });
}
