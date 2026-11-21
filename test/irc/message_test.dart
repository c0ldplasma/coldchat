import 'package:coldchat/irc/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message.fromEvent', () {
    test('parses a Twitch PRIVMSG with tags, prefix and trailing text', () {
      const line =
          '@badge-info=subscriber/8;badges=subscriber/6,premium/1;color=#1E90FF;display-name=Ronni;'
          'emotes=25:0-4,12-16/1902:6-10;first-msg=0;id=b34ccfc7-4977-403a-8a94-33c6bac34fb8;mod=0;room-id=12826;'
          'subscriber=1;tmi-sent-ts=1507246572675;turbo=0;user-id=1337;user-type= '
          ':ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :Kappa Keepo Kappa';

      final message = Message.fromEvent(line);

      expect(message.raw, line);
      expect(message.prefix, 'ronni!ronni@ronni.tmi.twitch.tv');
      expect(message.command, 'PRIVMSG');
      expect(message.parameters, ['#ronni', 'Kappa Keepo Kappa']);
      expect(message.tags, {
        'badge-info': 'subscriber/8',
        'badges': 'subscriber/6,premium/1',
        'color': '#1E90FF',
        'display-name': 'Ronni',
        'emotes': '25:0-4,12-16/1902:6-10',
        'first-msg': '0',
        'id': 'b34ccfc7-4977-403a-8a94-33c6bac34fb8',
        'mod': '0',
        'room-id': '12826',
        'subscriber': '1',
        'tmi-sent-ts': '1507246572675',
        'turbo': '0',
        'user-id': '1337',
        'user-type': '',
      });
    });

    test('unescapes tag values, e.g. the system-msg of a USERNOTICE', () {
      const line =
          r'@badges=staff/1,broadcaster/1;color=#008000;display-name=ronni;id=db25007f-7a18-43eb-9379-80131e44d633;'
          r'login=ronni;msg-id=resub;msg-param-cumulative-months=6;msg-param-sub-plan=Prime;'
          r'system-msg=ronni\shas\ssubscribed\sfor\s6\smonths!;user-id=1337 '
          ':tmi.twitch.tv USERNOTICE #dallas :Great stream -- keep it up!';

      final message = Message.fromEvent(line);

      expect(message.prefix, 'tmi.twitch.tv');
      expect(message.command, 'USERNOTICE');
      expect(message.parameters, ['#dallas', 'Great stream -- keep it up!']);
      expect(message.tags['system-msg'], 'ronni has subscribed for 6 months!');
      expect(message.tags['msg-param-sub-plan'], 'Prime');
    });

    test('keeps "=" inside a tag value and skips tags without "="', () {
      final message = Message.fromEvent('@a=b=c;flag;d= :x PING :y');

      expect(message.tags, {'a': 'b=c', 'd': ''});
    });

    test('keeps spaces and colons in the trailing parameter', () {
      final message = Message.fromEvent(':nick!nick@nick.tmi.twitch.tv PRIVMSG #chan :at 12:30 :) see https://x.tv');

      expect(message.parameters, ['#chan', 'at 12:30 :) see https://x.tv']);
    });

    test('parses several middle parameters', () {
      final message = Message.fromEvent(':tmi.twitch.tv 353 justinfan123 = #chan :alice bob');

      expect(message.command, '353');
      expect(message.parameters, ['justinfan123', '=', '#chan', 'alice bob']);
    });

    test('parses a message without tags and prefix', () {
      final message = Message.fromEvent('PING :tmi.twitch.tv');

      expect(message.tags, isEmpty);
      expect(message.prefix, isNull);
      expect(message.command, 'PING');
      expect(message.parameters, ['tmi.twitch.tv']);
    });

    test('parses a command without parameters', () {
      final message = Message.fromEvent(':tmi.twitch.tv RECONNECT');

      expect(message.command, 'RECONNECT');
      expect(message.parameters, isEmpty);
    });

    test('throws when there is no command after tags and prefix', () {
      expect(() => Message.fromEvent('@id=1 :tmi.twitch.tv'), throwsA(isA<InvalidIrcMessageException>()));
      expect(() => Message.fromEvent('@id=1'), throwsA(isA<InvalidIrcMessageException>()));
    });

    test(
      'throws for an empty line',
      () {
        expect(() => Message.fromEvent(''), throwsA(isA<InvalidIrcMessageException>()));
      },
    );
  });

  group('Message.unescapeTagValue', () {
    test('returns a value without backslashes unchanged', () {
      const value = 'plain value; with: stuff';
      expect(identical(Message.unescapeTagValue(value), value), isTrue);
    });

    test('unescapes the IRCv3 escapes', () {
      expect(Message.unescapeTagValue(r'a\sb'), 'a b');
      expect(Message.unescapeTagValue(r'a\:b'), 'a;b');
      expect(Message.unescapeTagValue(r'a\\b'), r'a\b');
      expect(Message.unescapeTagValue(r'a\rb'), 'a\rb');
      expect(Message.unescapeTagValue(r'a\nb'), 'a\nb');
    });

    test('drops the backslash of an unknown escape', () {
      expect(Message.unescapeTagValue(r'a\bc'), 'abc');
    });

    test('drops a trailing lone backslash', () {
      expect(Message.unescapeTagValue(r'abc\'), 'abc');
    });

    test('unescapes several escapes in a row', () {
      expect(Message.unescapeTagValue(r'\s\:\\\s'), r' ;\ ');
    });
  });

  group('Message.commandOf', () {
    test('finds the command after tags and a prefix, after a prefix only and with neither', () {
      expect(Message.commandOf('@id=1;user-id=2 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hi there'), 'PRIVMSG');
      expect(Message.commandOf('@badges=;color= :tmi.twitch.tv USERSTATE #ronni'), 'USERSTATE');
      expect(Message.commandOf(':ronni!ronni@ronni.tmi.twitch.tv JOIN #ronni'), 'JOIN');
      expect(Message.commandOf('PING :tmi.twitch.tv'), 'PING');
      expect(Message.commandOf('RECONNECT'), 'RECONNECT');
    });

    test('finds numeric commands', () {
      expect(Message.commandOf(':tmi.twitch.tv 001 justinfan123 :Welcome, GLHF!'), '001');
      expect(Message.commandOf(':justinfan123.tmi.twitch.tv 353 justinfan123 = #ronni :justinfan123'), '353');
    });

    test('is null for lines without a command, where fromEvent throws', () {
      for (final line in [
        '',
        '@id=1',
        '@id=1 ',
        ':tmi.twitch.tv',
        '@id=1 :tmi.twitch.tv',
        ' PING',
        '@a=b  PRIVMSG #x :two spaces',
      ]) {
        expect(Message.commandOf(line), isNull, reason: line);
        expect(() => Message.fromEvent(line), throwsA(isA<InvalidIrcMessageException>()), reason: line);
      }
    });

    test('agrees with fromEvent', () {
      for (final line in [
        '@id=1;user-id=2 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hi there',
        '@login=ronni;target-msg-id=m1 :tmi.twitch.tv CLEARMSG #ronni :hello',
        '@msg-id=slow_on :tmi.twitch.tv NOTICE #ronni :This room is now in slow mode.',
        ':tmi.twitch.tv CAP * ACK :twitch.tv/tags twitch.tv/commands',
        ':tmi.twitch.tv 001 justinfan123 :Welcome, GLHF!',
        'PING :tmi.twitch.tv',
        'RECONNECT',
      ]) {
        expect(Message.commandOf(line), Message.fromEvent(line).command, reason: line);
      }
    });
  });
}
