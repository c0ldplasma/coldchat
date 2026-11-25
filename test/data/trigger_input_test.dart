import 'package:coldchat/data/message_trigger.dart';
import 'package:coldchat/data/trigger_input.dart';
import 'package:flutter_test/flutter_test.dart';

MessageTriggerInput parse(String text, {bool enableRegex = false, bool caseSensitive = false}) =>
    parseMessageTriggerInput(text, enableRegex: enableRegex, caseSensitive: caseSensitive);

bool matches(MessageTriggerEntry entry, String body) => MessageTrigger(
  type: MessageTriggerType.mention.index,
  pattern: entry.pattern,
  enableRegex: entry.enableRegex,
  caseSensitive: entry.caseSensitive,
).matchesRegex(body);

void main() {
  group('parseMessageTriggerInput', () {
    test('makes one trigger per line, skipping empty lines and repeats', () {
      final input = parse('hello\n\n  good morning, chat  \r\nhello\n');

      expect(input.entries.map((entry) => entry.pattern), ['hello', 'good morning, chat']);
      expect(input.invalidLine, isNull);
    });

    test('takes the checkboxes for lines without a prefix', () {
      final entry = parse('a|b', enableRegex: true, caseSensitive: true).entries.single;

      expect(entry, (pattern: 'a|b', enableRegex: true, caseSensitive: true));
    });

    test('reports the first line with an invalid regex', () {
      final input = parse('ok\n(\n[', enableRegex: true);

      expect(input.invalidLine, 2);
      expect(input.entries, hasLength(3));
    });

    test('a single plain line is never invalid', () {
      expect(parse('(').invalidLine, isNull);
    });

    test("accepts Chatty's regex syntax, like (?i)", () {
      final input = parse(r'(?i)\bcoldchat\b', enableRegex: true, caseSensitive: true);

      expect(input.invalidLine, isNull);
      expect(matches(input.entries.single, 'I like ColdChat'), isTrue);
    });

    group('Chatty prefixes', () {
      test('regex prefixes override the checkboxes', () {
        expect(parse('reg:Foo.*').entries.single, (pattern: 'Foo.*', enableRegex: true, caseSensitive: true));
        expect(parse('re*:Foo').entries.single, (pattern: 'Foo', enableRegex: true, caseSensitive: true));
        expect(parse('regi:foo').entries.single, (pattern: 'foo', enableRegex: true, caseSensitive: false));
      });

      test('regw and regm add boundaries and anchors', () {
        final word = parse('regwi:hi|hey').entries.single;
        expect(matches(word, 'oh HEY there'), isTrue);
        expect(matches(word, 'they'), isFalse);

        final whole = parse('regm:Test').entries.single;
        expect(matches(whole, 'Test'), isTrue);
        expect(matches(whole, 'Test '), isFalse);
        expect(parse('re:Test').entries.single, whole);
      });

      test('plain-text prefixes', () {
        expect(parse('text:a.b', enableRegex: true).entries.single, (
          pattern: 'a.b',
          enableRegex: false,
          caseSensitive: false,
        ));
        expect(parse('cs:Hi').entries.single, (pattern: 'Hi', enableRegex: false, caseSensitive: true));

        final word = parse('w:c++').entries.single;
        expect(matches(word, 'I write C++ daily'), isTrue);
        expect(matches(word, 'abc++'), isFalse);
        expect(matches(parse('wcs:Hi').entries.single, 'hi'), isFalse);

        final start = parse('start:!bet').entries.single;
        expect(matches(start, '!BET 100'), isTrue);
        expect(matches(start, 'no !bet'), isFalse);
        expect(matches(parse('startw:!bet').entries.single, '!betting'), isFalse);
      });

      test('an invalid regex after a prefix is reported even with the regex checkbox off', () {
        expect(parse('ok\nregi:(').invalidLine, 2);
      });

      test('other colons stay part of the pattern', () {
        expect(parse('note: hi').entries.single.pattern, 'note: hi');
        expect(parse('user:someone').entries.single.pattern, 'user:someone');
        expect(parse('https://example.com').entries.single.pattern, 'https://example.com');
      });
    });
  });

  group('parseUserTriggerInput', () {
    test('splits at commas, semicolons, spaces and new lines', () {
      expect(parseUserTriggerInput('alice, bob;carol\n dave  eve'), ['alice', 'bob', 'carol', 'dave', 'eve']);
    });

    test("drops @ and Chatty's user: prefix, and repeats ignoring case", () {
      expect(parseUserTriggerInput('@Alice user:bob alice @'), ['Alice', 'bob']);
    });

    test('is empty for blank input', () {
      expect(parseUserTriggerInput('  ,\n'), isEmpty);
    });
  });
}
