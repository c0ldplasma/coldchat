import 'package:coldchat/data/emote.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/tools/emotes/emote_picker_sections.dart';
import 'package:coldchat/tools/emotes/emote_section_order.dart';
import 'package:flutter_test/flutter_test.dart';

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

Emote _emote(String name, ChatSource source, {String? category, String? ownerId}) =>
    Emote(id: name, name: name, mipmap: const [''], source: source, category: category, ownerId: ownerId);

List<String> _ordered(List<String> defaults, List<String> saved) => orderSections(defaults, (key) => key, saved);

void main() {
  group('orderSections', () {
    test('keeps the default order while nothing was arranged', () {
      final defaults = ['a', 'b', 'c'];
      expect(orderSections(defaults, (key) => key, const []), same(defaults));
    });

    test('puts arranged sections in the saved order', () {
      expect(_ordered(['a', 'b', 'c'], ['c', 'a', 'b']), ['c', 'a', 'b']);
    });

    test('puts a section that was never arranged right after the one before it by default', () {
      // A new sub's section "n" comes after "b" by default.
      expect(_ordered(['a', 'b', 'n', 'c'], ['c', 'b', 'a']), ['c', 'b', 'n', 'a']);
      // Several new ones in a row stay together, in their order.
      expect(_ordered(['a', 'n1', 'n2', 'b'], ['b', 'a']), ['b', 'a', 'n1', 'n2']);
      // One that is first by default stays first.
      expect(_ordered(['n', 'a', 'b'], ['b', 'a']), ['n', 'b', 'a']);
    });

    test('skips saved sections that aren\'t there, keeping the others\' order', () {
      expect(_ordered(['a', 'c'], ['c', 'gone', 'a']), ['c', 'a']);
    });
  });

  group('arrangeableEmoteSections', () {
    test('lists the sections of every open chat and of the hidden ones, in the saved order', () {
      final sections = arrangeableEmoteSections(
        channelEmoteLists: [
          [_emote('peepoHappy', _sevenTv)],
          [_emote('catJAM', _bttv)],
        ],
        globalEmotes: [_emote('Kappa', _twitch)],
        userEmotes: [_emote('ronniHi', _twitch, category: 'Ronni', ownerId: '1')],
        hidden: {'2': 'Anime_Marathon_1', 'section:FrankerFaceZ': 'FrankerFaceZ', 'section:7TV': '7TV'},
        savedOrder: ['1', 'section:7TV', 'section:Twitch'],
      );

      // By default: the open chats' 7TV and BetterTTV, Twitch, Ronni, then the hidden ones without emotes now.
      // Those not arranged yet follow their default predecessor: BetterTTV after 7TV, Anime_Marathon_1 after Ronni,
      // FrankerFaceZ after Anime_Marathon_1.
      expect(
        [for (final section in sections) (section.key, section.title)],
        [
          ('1', 'Ronni'),
          ('2', 'Anime_Marathon_1'),
          ('section:FrankerFaceZ', 'FrankerFaceZ'),
          ('section:7TV', '7TV'),
          ('section:BetterTTV', 'BetterTTV'),
          ('section:Twitch', 'Twitch'),
        ],
      );
      // A hidden section without emotes now is listed empty, keyed as it was hidden.
      expect(sections[1].emotes, isEmpty);
      expect(sections[1].ownerId, '2');
      expect(sections[2].ownerId, isNull);
      // A hidden section that is there is listed with its emotes.
      expect(sections[3].emotes.map((emote) => emote.name), ['peepoHappy']);
    });
  });

  test('reorderedSectionKeys moves one section, as the reorderable list reports it', () {
    final sections = [
      for (final title in ['a', 'b', 'c', 'd']) EmoteSection(title, const []),
    ];

    expect(reorderedSectionKeys(sections, 0, 2), ['section:b', 'section:c', 'section:a', 'section:d']);
    expect(reorderedSectionKeys(sections, 3, 0), ['section:d', 'section:a', 'section:b', 'section:c']);
  });
}
