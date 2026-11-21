import 'dart:io';

import '../api/emojis/emoji_data.dart';
import '../api/json_isolate.dart';
import '../data/emote.dart';
import 'chat_source.dart';
import 'emote_source.dart';

class EmojiSource extends ChatSource with EmoteSource {
  final EmojiDataApi api;

  EmojiSource(this.api);

  @override
  String get name => 'Emoji';

  @override
  String? get description => null;

  @override
  Future<List<Emote>> globalEmotes() async {
    final entries = await api.emojis();
    // Emojis render as text in the platform's emoji font, so only list the
    // ones that font has; anything newer would show as an empty box.
    final supportedKey = Platform.isIOS ? 'has_img_apple' : 'has_img_google';
    // The file is in codepoint order. Use Unicode's order instead (Smileys &
    // Emotion first), with the bare skin tone swatches ("Component") at the end.
    int rank(JsonMap entry) => (entry['category'] == 'Component' ? 100000 : 0) + (entry['sort_order'] as int);
    final emojis = entries.where((entry) => entry[supportedKey] == true).toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    return [
      for (final emojiData in emojis)
        Emote(
          id: emojiData['unified'] as String,
          code: (emojiData['unified'] as String)
              .split('-')
              .map((x) => String.fromCharCode(int.parse(x, radix: 16)))
              .join(),
          name: emojiData['short_name'] as String,
          mipmap: [EmojiDataApi.imageUrl('${emojiData['image']}')],
          source: this,
          category: emojiData['category'] as String?,
        ),
    ];
  }

  @override
  Future<List<Emote>> channelEmotes(String uid) async {
    return [];
  }

  @override
  String? emoteUrl(String id) => null;
}
