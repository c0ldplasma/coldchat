import 'package:coldchat/data/emote.dart';
import 'package:coldchat/providers/emojis.dart';
import 'package:coldchat/providers/provider.dart';
import 'package:coldchat/widgets/chat/emote_picker_sections.dart';
import 'package:flutter_test/flutter_test.dart';

class _Provider extends Provider {
  @override
  final String name;

  _Provider(this.name);

  @override
  String? get description => null;
}

final _twitch = _Provider('Twitch');
final _sevenTv = _Provider('7TV');
final _bttv = _Provider('BetterTTV');
final _emoji = EmojiProvider();

Emote _emote(String name, Provider provider, {String? category}) =>
    Emote(id: name, name: name, mipmap: ['https://example.com/$name'], provider: provider, category: category);

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
}
