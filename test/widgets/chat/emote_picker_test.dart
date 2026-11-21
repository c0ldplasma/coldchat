import 'package:coldchat/api/emojis/emoji_data.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/providers/emojis.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:coldchat/tmi/client/chat_globals.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/widgets/chat/emote_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../api/fake_api.dart';

/// Just the emote lists the picker reads from the client. The real [Client] opens connections and timers.
class _FakeClient implements Client {
  @override
  late final ChatGlobals globals = ChatGlobals(providers: const [], onBadgesChanged: () {}, onUserBadgeChanged: (_) {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _emoji = EmojiProvider(EmojiDataApi(offlineApi()));

/// An emoji, drawn as text so the test loads no images.
Emote _emojiEmote(String name, String code, String category) =>
    Emote(id: name, name: name, code: code, mipmap: const [''], provider: _emoji, category: category);

void main() {
  testWidgets('shows newly loaded emotes and filters by the search', (tester) async {
    final client = _FakeClient();
    addTearDown(client.globals.emotes.close);
    addTearDown(client.globals.twitchUserEmotes.close);
    client.globals.emotes.change([
      _emojiEmote('grinning', '😀', 'Smileys & Emotion'),
      _emojiEmote('dog', '🐶', 'Animals & Nature'),
    ]);
    final inserted = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: SizedBox(
            height: 350.0,
            child: EmotePicker(
              client: client,
              getFieldInput: () => '',
              setFieldInput: (_) {},
              insertFieldInput: inserted.add,
            ),
          ),
        ),
      ),
    );

    // Twitch's section waits for its emotes with a spinner, before the emoji sections.
    expect(find.text('Twitch'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Smileys & Emotion'), findsOneWidget);
    expect(find.text('😀'), findsOneWidget);
    expect(find.text('🐶'), findsOneWidget);

    // Emotes that load while the picker is open show up.
    client.globals.emotes.change([...client.globals.emotes.state, _emojiEmote('smile', '😄', 'Smileys & Emotion')]);
    await tester.pump();
    expect(find.text('😄'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'DO');
    await tester.pump();
    expect(find.text('🐶'), findsOneWidget);
    expect(find.text('😀'), findsNothing);
    expect(find.text('😄'), findsNothing);
    expect(find.text('Smileys & Emotion'), findsNothing);
    expect(find.text('Twitch'), findsNothing);

    await tester.tap(find.text('🐶'));
    expect(inserted, ['🐶']);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('😀'), findsOneWidget);
    expect(find.text('😄'), findsOneWidget);
    expect(find.text('Twitch'), findsOneWidget);
  });
}
