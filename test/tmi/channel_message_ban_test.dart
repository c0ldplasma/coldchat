import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/channel/channel_messages.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_ban.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_id.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1 s timeout of storereview28374 in #c0ldplasma, as Twitch sends it live.
const _timeout =
    '@ban-duration=1;room-id=123456;target-user-id=987654;tmi-sent-ts=1763712000000 '
    ':tmi.twitch.tv CLEARCHAT #c0ldplasma :storereview28374';

/// The same timeout from recent-messages.robotty.de, which adds its own tags to the line.
const _timeoutFromHistory =
    '@ban-duration=1;historical=1;rm-received-ts=1763712000123;room-id=123456;target-user-id=987654;'
    'tmi-sent-ts=1763712000000 :tmi.twitch.tv CLEARCHAT #c0ldplasma :storereview28374';

/// A second timeout of the same user, ten minutes later.
const _laterTimeout =
    '@ban-duration=600;room-id=123456;target-user-id=987654;tmi-sent-ts=1763712600000 '
    ':tmi.twitch.tv CLEARCHAT #c0ldplasma :storereview28374';

const _ban =
    '@room-id=123456;target-user-id=987654;tmi-sent-ts=1763713000000 '
    ':tmi.twitch.tv CLEARCHAT #c0ldplasma :storereview28374';

const _chatCleared = '@room-id=123456;tmi-sent-ts=1763714000000 :tmi.twitch.tv CLEARCHAT #c0ldplasma';

const _chatMessage =
    '@id=b34ccfc7-4977-403a-8a94-33c6bac34fb8;room-id=123456;tmi-sent-ts=1763711000000;user-id=1 '
    ':ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #c0ldplasma :hello';

ChannelMessageBan _build(String line) {
  final message = irc.Message.fromEvent(line);
  return ChannelMessageBan(
    message: message,
    dateTime: DateTime.fromMillisecondsSinceEpoch(int.tryParse(message.tags['tmi-sent-ts'] ?? '') ?? 0),
  );
}

ChannelMessages _messages() {
  final messages = ChannelMessages();
  addTearDown(messages.close);
  return messages;
}

/// One pass of `Client.insertHistoryMessages`: lines whose id the chat already shows are skipped before they're
/// built, the rest is added in bulk.
void _insertHistory(ChannelMessages messages, List<String> lines) {
  final existingIds = messages.state.whereType<ChannelMessageId>().map((e) => e.id).toSet();
  messages.beginBulk();
  for (final line in lines) {
    final id = ircMessageId(irc.Message.fromEvent(line));
    if (id != null && !existingIds.add(id)) continue;
    messages.add(_build(line));
  }
  messages.endBulk();
}

void main() {
  group('ChannelMessageBan.idOf', () {
    test('is the same for the live line and its copy in the history', () {
      expect(ChannelMessageBan.idOf(irc.Message.fromEvent(_timeout)), 'clearchat:123456:987654:1763712000000');
      expect(
        ChannelMessageBan.idOf(irc.Message.fromEvent(_timeoutFromHistory)),
        ChannelMessageBan.idOf(irc.Message.fromEvent(_timeout)),
      );
    });

    test('differs for two timeouts of the same user', () {
      expect(
        ChannelMessageBan.idOf(irc.Message.fromEvent(_laterTimeout)),
        isNot(ChannelMessageBan.idOf(irc.Message.fromEvent(_timeout))),
      );
    });

    test('has an empty user for a cleared chat', () {
      expect(ChannelMessageBan.idOf(irc.Message.fromEvent(_chatCleared)), 'clearchat:123456::1763714000000');
    });

    test('is null without tmi-sent-ts, and each such message gets an id of its own', () {
      const line = '@ban-duration=1;room-id=123456;target-user-id=987654 :tmi.twitch.tv CLEARCHAT #c0ldplasma :x';
      expect(ChannelMessageBan.idOf(irc.Message.fromEvent(line)), isNull);
      expect(_build(line).id, isNot(_build(line).id));
    });
  });

  group('ircMessageId', () {
    test('is the id tag for chat messages and the CLEARCHAT id for bans', () {
      expect(ircMessageId(irc.Message.fromEvent(_chatMessage)), 'b34ccfc7-4977-403a-8a94-33c6bac34fb8');
      expect(ircMessageId(irc.Message.fromEvent(_timeout)), _build(_timeout).id);
    });
  });

  group('duplicate bans', () {
    test('a timeout in all three history passes shows once', () {
      final messages = _messages();
      for (var pass = 0; pass < 3; pass++) {
        _insertHistory(messages, [_timeoutFromHistory]);
      }
      expect(messages.state, hasLength(1));
    });

    test('ChannelMessages drops a repeated timeout itself, in bulk and outside it', () {
      final messages = _messages();
      messages.beginBulk();
      messages.add(_build(_timeoutFromHistory));
      messages.add(_build(_timeoutFromHistory));
      messages.endBulk();
      messages.add(_build(_timeout));
      expect(messages.state, hasLength(1));
    });

    test('a timeout received live and again in the backfill after JOIN shows once', () {
      final messages = _messages();
      messages.add(_build(_timeout));
      _insertHistory(messages, [_timeoutFromHistory]);
      expect(messages.state, hasLength(1));
    });

    test('two timeouts of the same user both show', () {
      final messages = _messages();
      _insertHistory(messages, [_timeout, _laterTimeout]);
      _insertHistory(messages, [_timeout, _laterTimeout]);
      expect(messages.state.map((m) => (m as ChannelMessageBan).duration), [
        const Duration(seconds: 1),
        const Duration(minutes: 10),
      ]);
    });

    test('a cleared chat shows once', () {
      final messages = _messages();
      _insertHistory(messages, [_chatCleared]);
      messages.add(_build(_chatCleared));
      _insertHistory(messages, [_chatCleared]);
      expect(messages.state, hasLength(1));
    });
  });

  group('duration', () {
    test('is the ban-duration of a timeout', () {
      expect(_build(_timeout).duration, const Duration(seconds: 1));
    });

    test('is null for a permanent ban and a cleared chat', () {
      expect(_build(_ban).user?.login, 'storereview28374');
      expect(_build(_ban).duration, isNull);
      expect(_build(_chatCleared).user, isNull);
      expect(_build(_chatCleared).duration, isNull);
    });
  });
}
