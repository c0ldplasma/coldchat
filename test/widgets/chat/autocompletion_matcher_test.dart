import 'package:coldchat/data/emote.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/providers/provider.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/channel_message.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:coldchat/tmi/user.dart';
import 'package:coldchat/widgets/chat/autocompletion_matcher.dart';
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

Emote _emote(String name, Provider provider) =>
    Emote(id: name, name: name, mipmap: ['https://example.com/$name'], provider: provider);

/// A chat message from [login] (shown as [displayName]), sent [minute] minutes after the first.
ChannelMessageChat _chat(String login, int minute, {String? displayName}) => ChannelMessageChat(
  message: irc.Message.fromEvent(
    '@display-name=${displayName ?? login};id=$login-$minute;user-id=$login '
    ':$login!$login@$login.tmi.twitch.tv PRIVMSG #ronni :hi',
  ),
  dateTime: DateTime(2026, 11, 20).add(Duration(minutes: minute)),
);

List<String> _names(List<Emote> emotes) => [for (final emote in emotes) emote.name];

List<String?> _logins(List<User> users) => [for (final user in users) user.login];

void main() {
  group('emotes', () {
    final channelEmotes = [_emote('peepoHappy', _sevenTv), _emote('EZ', _sevenTv), _emote('happyCat', _sevenTv)];
    final globalEmotes = [_emote('Kappa', _twitch), _emote('KappaPride', _twitch)];
    final userEmotes = [_emote('ronniHappy', _twitch), _emote('HappyJack', _twitch)];

    List<Emote> match(AutocompletionMatcher matcher, String search, {bool needsColon = false}) => matcher.emotes(
      channelEmotes: channelEmotes,
      globalEmotes: globalEmotes,
      userEmotes: userEmotes,
      search: search,
      needsColon: needsColon,
    );

    test('puts names starting with the search first, each group in channel, global, user order', () {
      final matcher = AutocompletionMatcher();
      expect(_names(match(matcher, 'happy')), ['happyCat', 'HappyJack', 'peepoHappy', 'ronniHappy']);
      expect(_names(match(matcher, 'kappa')), ['Kappa', 'KappaPride']);
    });

    test('matches the :name: form, so a colon finds the start or the end of a name', () {
      final matcher = AutocompletionMatcher();
      expect(_names(match(matcher, ':happy')), ['happyCat', 'HappyJack']);
      expect(_names(match(matcher, 'happy:')), ['peepoHappy', 'ronniHappy']);
      expect(_names(match(matcher, ':ez:')), ['EZ']);
    });

    test('with the colon setting, matches only a search starting with a colon', () {
      final matcher = AutocompletionMatcher();
      expect(match(matcher, 'happy', needsColon: true), isEmpty);
      expect(_names(match(matcher, ':kap', needsColon: true)), ['Kappa', 'KappaPride']);
    });

    test('searches again only when the search, the setting or an emote list changes', () {
      final matcher = AutocompletionMatcher();
      final first = match(matcher, 'happy');
      expect(match(matcher, 'happy'), same(first));
      expect(match(matcher, 'happy', needsColon: true), isEmpty);
      expect(_names(match(matcher, 'happy')), _names(first));

      // Newly loaded emotes come as a new list, like a cubit emits them.
      final newlyLoaded = matcher.emotes(
        channelEmotes: [...channelEmotes, _emote('happyHour', _sevenTv)],
        globalEmotes: globalEmotes,
        userEmotes: userEmotes,
        search: 'happy',
        needsColon: false,
      );
      expect(_names(newlyLoaded), ['happyCat', 'happyHour', 'HappyJack', 'peepoHappy', 'ronniHappy']);
    });
  });

  group('chatters', () {
    final List<ChannelMessage> messages = [
      _chat('ronni', 0, displayName: 'Ronni'),
      _chat('forsen', 1),
      _chat('ronni', 2),
      _chat('xqc', 3),
    ];

    test('lists each chatter once, most recent first, like Channel.recentChatters', () {
      expect(_logins(Channel.chattersIn(messages)), ['xqc', 'ronni', 'forsen']);
      final matcher = AutocompletionMatcher();
      expect(_logins(matcher.chatters(messages: messages, search: 'r', needsAt: false)), ['ronni', 'forsen']);
      expect(_logins(matcher.chatters(messages: messages, search: '@x', needsAt: false)), ['xqc']);
    });

    test('with the @ setting, matches only a search starting with @', () {
      final matcher = AutocompletionMatcher();
      expect(matcher.chatters(messages: messages, search: 'ronni', needsAt: true), isEmpty);
      expect(_logins(matcher.chatters(messages: messages, search: '@ron', needsAt: true)), ['ronni']);
    });

    test('collects the chatters again only when the messages change, so new chatters appear', () {
      final matcher = AutocompletionMatcher();
      final first = matcher.chatters(messages: messages, search: '@', needsAt: true);
      expect(matcher.chatters(messages: messages, search: '@', needsAt: true), same(first));

      // A new message comes as a new list, like ChannelMessages emits it.
      final withNewChatter = [...messages, _chat('pokimane', 4)];
      expect(_logins(matcher.chatters(messages: withNewChatter, search: '@', needsAt: true)), [
        'pokimane',
        'xqc',
        'ronni',
        'forsen',
      ]);
    });
  });
}
