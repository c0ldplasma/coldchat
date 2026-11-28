import 'package:coldchat/data/emote.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/tools/emotes/visible_emotes.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source extends ChatSource {
  @override
  String get name => 'Twitch';

  @override
  String? get description => null;
}

final _twitch = _Source();

Emote _emote(String name, {String? ownerId}) =>
    Emote(id: name, name: name, mipmap: const [''], source: _twitch, ownerId: ownerId);

void main() {
  final emotes = [_emote('Kappa'), _emote('animeHi', ownerId: '1'), _emote('ronniHi', ownerId: '2')];

  test('leaves out the emotes of hidden channels', () {
    final visible = VisibleEmotes().of(emotes, {'1'});

    expect(visible.map((emote) => emote.name), ['Kappa', 'ronniHi']);
  });

  test('is the list given when no emote in it is hidden', () {
    expect(VisibleEmotes().of(emotes, const {}), same(emotes));
    expect(VisibleEmotes().of(emotes, {'3'}), same(emotes));
  });

  test('filters again only when the list or the hidden channels change', () {
    final visibleEmotes = VisibleEmotes();
    final first = visibleEmotes.of(emotes, {'1'});

    // An equal set in a new object, as each rebuild reads it from the settings.
    expect(visibleEmotes.of(emotes, {'1'}), same(first));
    expect(visibleEmotes.of(emotes, {'1', '2'}).map((emote) => emote.name), ['Kappa']);
    expect(visibleEmotes.of([...emotes], {'1', '2'}).map((emote) => emote.name), ['Kappa']);
    expect(visibleEmotes.of(emotes, const {}), same(emotes));
  });
}
