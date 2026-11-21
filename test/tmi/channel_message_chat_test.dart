import 'package:coldchat/data/emote.dart';
import 'package:coldchat/data/inline_url.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:coldchat/tmi/channel/messages/embeds/image_embed.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// A PRIVMSG from `ronni` in `#ronni` with [text] and the given extra tags.
ChannelMessageChat chat(String text, {String tags = ''}) {
  final line =
      '@color=#1E90FF;display-name=Ronni;id=b34ccfc7-4977-403a-8a94-33c6bac34fb8;user-id=1337$tags '
      ':ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :$text';
  return ChannelMessageChat(message: irc.Message.fromEvent(line), dateTime: DateTime(2026, 11, 20));
}

/// The id and name of a Twitch emote in [ChannelMessageChat.splits], to compare splits in one line.
Matcher isTwitchEmote(String id, String name) => isA<Emote>()
    .having((e) => e.id, 'id', id)
    .having((e) => e.name, 'name', name)
    .having((e) => e.mipmap.first, 'mipmap.first', 'https://static-cdn.jtvnw.net/emoticons/v2/$id/default/dark/1.0');

void main() {
  test('reads id, user and body', () {
    final message = chat('hello chat');

    expect(message.id, 'b34ccfc7-4977-403a-8a94-33c6bac34fb8');
    expect(message.user.login, 'ronni');
    expect(message.user.displayName, 'Ronni');
    expect(message.user.id, '1337');
    expect(message.body, 'hello chat');
    expect(message.splits, ['hello', 'chat']);
    expect(message.action, isFalse);
    expect(message.replyInfo, isNull);
  });

  test('turns an escaped zero width joiner (U+E0002) back into U+200D', () {
    // 👨 U+E0002 💻 is how a Chatterino-style client escapes 👨‍💻.
    final message = chat('\u{1F468}\u{E0002}\u{1F4BB} hi');

    expect(message.body, '\u{1F468}\u{200D}\u{1F4BB} hi');
    expect(message.splits, ['\u{1F468}\u{200D}\u{1F4BB}', 'hi']);
  });

  group('user color', () {
    test('comes from the color tag', () {
      expect(chat('hi').user.color, const Color(0xFF1E90FF));
    });

    test('is null when the color tag is empty', () {
      expect(chat('hi', tags: ';color=').user.color, isNull);
    });
  });

  group('Twitch emotes', () {
    test('replaces a single emote', () {
      final message = chat('hi Kappa there', tags: ';emotes=25:3-7');

      expect(message.splits, ['hi', isTwitchEmote('25', 'Kappa'), 'there']);
      // The body keeps the original text.
      expect(message.body, 'hi Kappa there');
    });

    test('replaces several emotes', () {
      final message = chat('Kappa Keepo PogChamp', tags: ';emotes=25:0-4/1902:6-10/305954156:12-19');

      expect(message.splits, [
        isTwitchEmote('25', 'Kappa'),
        isTwitchEmote('1902', 'Keepo'),
        isTwitchEmote('305954156', 'PogChamp'),
      ]);
    });

    test('replaces every instance of the same emote', () {
      final message = chat('Kappa lol Kappa', tags: ';emotes=25:0-4,10-14');

      expect(message.splits, [isTwitchEmote('25', 'Kappa'), 'lol', isTwitchEmote('25', 'Kappa')]);
    });

    test('counts positions in code points, after a multi-code-unit emoji', () {
      // 👋 is one code point but two UTF-16 code units.
      final message = chat('👋 Kappa', tags: ';emotes=25:2-6');

      expect(message.splits, ['👋', isTwitchEmote('25', 'Kappa')]);
    });

    test('glues an emote to the text around it into separate splits', () {
      final message = chat('aKappab', tags: ';emotes=25:1-5');

      expect(message.splits, ['a', isTwitchEmote('25', 'Kappa'), 'b']);
    });

    test(
      'keeps a non-ASCII emote name',
      () {
        final message = chat('hi Käppa', tags: ';emotes=42:3-7');

        expect(message.splits, ['hi', isTwitchEmote('42', 'Käppa')]);
      },
    );

    test('leaves the text alone when the emotes tag is malformed', () {
      final message = chat('hi Kappa', tags: ';emotes=25:x-y');

      expect(message.splits, ['hi', 'Kappa']);
    });
  });

  group('/me', () {
    test('an ACTION message is marked and unwrapped', () {
      final message = chat('\x01ACTION waves\x01');

      expect(message.action, isTrue);
      expect(message.body, 'waves');
      expect(message.splits, ['waves']);
    });

    test('text merely containing ACTION is not an action', () {
      final message = chat('THE ACTION MOVIE');

      expect(message.action, isFalse);
      expect(message.body, 'THE ACTION MOVIE');
    });
  });

  group('links', () {
    test('become an InlineUrl', () {
      final message = chat('see https://example.com/page now');

      expect(message.splits, [
        'see',
        isA<InlineUrl>().having((u) => u.url, 'url', 'https://example.com/page'),
        'now',
      ]);
      expect(message.embeds.state, isEmpty);
    });

    test('to an image also add an ImageEmbed', () {
      final message = chat('look https://example.com/cat.png');

      expect(message.splits.last, isA<InlineUrl>().having((u) => u.url, 'url', 'https://example.com/cat.png'));
      expect(message.embeds.state, [
        isA<ImageEmbed>().having((e) => e.url, 'url', 'https://example.com/cat.png'),
      ]);
    });

    test(
      'with a #fragment become an InlineUrl',
      () {
        final message = chat('look https://example.com/cat.png#big');

        expect(message.splits.last, isA<InlineUrl>());
        expect(message.embeds.state, [isA<ImageEmbed>()]);
      },
    );

    test('without a scheme stay text', () {
      expect(chat('example.com').splits, ['example.com']);
    });
  });

  test('a reply skips the leading @mention', () {
    final message = chat(
      '@SupDos peepoLeave bye',
      tags:
          r';reply-parent-display-name=SupDos;reply-parent-msg-body=see\syou;'
          'reply-parent-msg-id=a11f6f0d-e4ad-4f61-a5b8-58a848ef2f7e;reply-parent-user-id=43983992;'
          'reply-parent-user-login=supdos',
    );

    expect(message.replyInfo!.replyParentDisplayName, 'SupDos');
    expect(message.replyInfo!.replyParentMsgBody, 'see you');
    expect(message.replyInfo!.replyParentMsgId, 'a11f6f0d-e4ad-4f61-a5b8-58a848ef2f7e');
    expect(message.replyInfo!.replyParentUserId, '43983992');
    expect(message.replyInfo!.replyParentUserLogin, 'supdos');
    expect(message.splits, ['peepoLeave', 'bye']);
    expect(message.body, '@SupDos peepoLeave bye');
  });
}
