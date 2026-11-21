import 'package:coldchat/data/message_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

MessageTrigger regexTrigger(String pattern, {bool caseSensitive = false}) => MessageTrigger(
  type: MessageTriggerType.mention.index,
  pattern: pattern,
  enableRegex: true,
  caseSensitive: caseSensitive,
);

void main() {
  group('regex message trigger', () {
    test('matches a valid pattern', () {
      expect(regexTrigger(r'\bhello\b').matchesRegex('well hello there'), isTrue);
      expect(regexTrigger(r'\bhello\b').matchesRegex('othello'), isFalse);
    });

    test('an invalid pattern matches nothing instead of throwing', () {
      final trigger = regexTrigger('(');

      expect(() => trigger.matchesRegex('anything ('), returnsNormally);
      expect(trigger.matchesRegex('anything ('), isFalse);
    });

    test('is case-insensitive unless caseSensitive is set', () {
      expect(regexTrigger('hello').matchesRegex('HELLO chat'), isTrue);
      expect(regexTrigger('hello', caseSensitive: true).matchesRegex('HELLO chat'), isFalse);
      expect(regexTrigger('hello', caseSensitive: true).matchesRegex('hello chat'), isTrue);
    });

    test('follows a changed pattern and flag', () {
      final trigger = regexTrigger('foo');
      expect(trigger.matchesRegex('FOO'), isTrue);

      trigger.caseSensitive = true;
      expect(trigger.matchesRegex('FOO'), isFalse);

      trigger.pattern = 'FOO';
      expect(trigger.matchesRegex('FOO'), isTrue);
    });
  });

  test('isValidRegex', () {
    expect(MessageTrigger.isValidRegex(r'^hi\s+\w+$'), isTrue);
    expect(MessageTrigger.isValidRegex('('), isFalse);
    expect(MessageTrigger.isValidRegex('[a-'), isFalse);
  });
}
