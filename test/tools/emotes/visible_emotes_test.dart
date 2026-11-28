import 'package:coldchat/data/emote.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/tools/emotes/visible_emotes.dart';
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

Emote _emote(String name, {ChatSource? source, String? ownerId, String? category}) => Emote(
  id: name,
  name: name,
  mipmap: const [''],
  source: source ?? _twitch,
  ownerId: ownerId,
  category: category,
);

void main() {
  final emotes = [
    _emote('Kappa'),
    _emote('animeHi', ownerId: '1', category: 'Anime_Marathon_1'),
    _emote('ronniHi', ownerId: '2', category: 'ronni'),
    _emote('peepoHappy', source: _sevenTv),
    _emote('grinning', category: 'Smileys & Emotion'),
  ];

  List<String> names(List<Emote> emotes) => [for (final emote in emotes) emote.name];

  test('leaves out the emotes of a hidden channel by its id', () {
    expect(names(VisibleEmotes().of(emotes, {'1'})), ['Kappa', 'ronniHi', 'peepoHappy', 'grinning']);
  });

  test('leaves out the emotes of any other hidden section by its title', () {
    expect(names(VisibleEmotes().of(emotes, {'section:7TV'})), ['Kappa', 'animeHi', 'ronniHi', 'grinning']);
    expect(names(VisibleEmotes().of(emotes, {'section:Smileys & Emotion'})), [
      'Kappa',
      'animeHi',
      'ronniHi',
      'peepoHappy',
    ]);
    // The Twitch section holds Twitch's emotes without a channel, not the channels' sections.
    expect(names(VisibleEmotes().of(emotes, {'section:Twitch'})), ['animeHi', 'ronniHi', 'peepoHappy', 'grinning']);
  });

  test('is the list given when no emote in it is hidden', () {
    expect(VisibleEmotes().of(emotes, const {}), same(emotes));
    expect(VisibleEmotes().of(emotes, {'3', 'section:BetterTTV'}), same(emotes));
  });

  test('filters again only when the list or the hidden sections change', () {
    final visibleEmotes = VisibleEmotes();
    final first = visibleEmotes.of(emotes, {'1'});

    // An equal set in a new object, as each rebuild reads it from the settings.
    expect(visibleEmotes.of(emotes, {'1'}), same(first));
    expect(names(visibleEmotes.of(emotes, {'1', '2'})), ['Kappa', 'peepoHappy', 'grinning']);
    expect(names(visibleEmotes.of([...emotes], {'1', '2'})), ['Kappa', 'peepoHappy', 'grinning']);
    expect(visibleEmotes.of(emotes, const {}), same(emotes));
  });
}
