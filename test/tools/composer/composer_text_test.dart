import 'package:coldchat/tools/composer/composer_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text, {int? caret, TextSelection? selection}) => TextEditingValue(
  text: text,
  selection: selection ?? TextSelection.collapsed(offset: caret ?? text.length),
);

const _invalid = TextSelection.collapsed(offset: -1);

/// The text with `|` at the collapsed caret.
String _show(TextEditingValue value) {
  expect(value.selection.isCollapsed, isTrue);
  final offset = value.selection.baseOffset;
  return '${value.text.substring(0, offset)}|${value.text.substring(offset)}';
}

void main() {
  group('completeLastWord', () {
    test('replaces the last word and adds a space, caret at the end', () {
      expect(_show(completeLastWord(_value('hello Kap'), 'Kappa')), 'hello Kappa |');
      expect(_show(completeLastWord(_value('Kap'), 'Kappa')), 'Kappa |');
    });

    test('after a trailing space replaces the empty last word', () {
      expect(_show(completeLastWord(_value('hello '), 'Kappa')), 'hello Kappa |');
      expect(_show(completeLastWord(_value(''), 'Kappa')), 'Kappa |');
    });

    test('keeps repeated spaces before the word', () {
      expect(_show(completeLastWord(_value('a  Kap'), 'Kappa')), 'a  Kappa |');
    });

    test('ignores where the caret or selection was', () {
      expect(_show(completeLastWord(_value('hello Kap', caret: 2), 'Kappa')), 'hello Kappa |');
      expect(_show(completeLastWord(_value('hello Kap', selection: _invalid), 'Kappa')), 'hello Kappa |');
      final range = _value('hello Kap', selection: const TextSelection(baseOffset: 0, extentOffset: 5));
      expect(_show(completeLastWord(range, 'Kappa')), 'hello Kappa |');
    });
  });

  group('appendWord', () {
    test('adds the word after a space, caret at the end', () {
      expect(_show(appendWord(_value(''), '@ronni')), '@ronni|');
      expect(_show(appendWord(_value('hi'), '@ronni')), 'hi @ronni|');
      expect(_show(appendWord(_value('hi', caret: 0), '@ronni')), 'hi @ronni|');
    });

    test('drops empty words', () {
      expect(_show(appendWord(_value('hi '), '@ronni')), 'hi @ronni|');
      expect(_show(appendWord(_value('  a   b  '), '@ronni')), 'a b @ronni|');
      expect(_show(appendWord(_value('hi '), '')), 'hi|');
    });
  });

  group('insertUploadedUrl', () {
    const url = 'https://i.example/a.png';

    test('without a valid selection appends with spaces around it', () {
      expect(_show(insertUploadedUrl(_value('', selection: _invalid), url)), '$url |');
      expect(_show(insertUploadedUrl(_value('hi', selection: _invalid), url)), 'hi $url |');
      expect(_show(insertUploadedUrl(_value('hi ', selection: _invalid), url)), 'hi $url |');
    });

    test('inserts at the caret', () {
      expect(_show(insertUploadedUrl(_value('hi', caret: 0), url)), '$url |hi');
      expect(_show(insertUploadedUrl(_value('hi there', caret: 3), url)), 'hi $url |there');
      expect(_show(insertUploadedUrl(_value('hi there'), url)), 'hi there $url |');
    });

    test('always adds a space after it, even before an existing one', () {
      expect(_show(insertUploadedUrl(_value('hi there', caret: 2), url)), 'hi $url | there');
    });

    test('replaces a selected range', () {
      const selection = TextSelection(baseOffset: 3, extentOffset: 6);
      expect(_show(insertUploadedUrl(_value('ab cd ef', selection: selection), url)), 'ab $url |ef');
      const reversed = TextSelection(baseOffset: 6, extentOffset: 3);
      expect(_show(insertUploadedUrl(_value('ab cd ef', selection: reversed), url)), 'ab $url |ef');
    });

    test('decides on the leading space by the text up to the end of the selected range', () {
      // The selected text doesn't end with a space, so a space is added although the range starts after one.
      const selection = TextSelection(baseOffset: 3, extentOffset: 5);
      expect(_show(insertUploadedUrl(_value('ab cd', selection: selection), url)), 'ab  $url |');
      const fromStart = TextSelection(baseOffset: 0, extentOffset: 2);
      expect(_show(insertUploadedUrl(_value('ab cd', selection: fromStart), url)), ' $url | cd');
    });
  });

  group('insertAtCaret', () {
    test('into empty text adds a space after it', () {
      expect(_show(insertAtCaret(_value(''), 'Kappa')), 'Kappa |');
      expect(_show(insertAtCaret(_value('', selection: _invalid), 'Kappa')), 'Kappa |');
    });

    test('at the end adds a space before and after it', () {
      expect(_show(insertAtCaret(_value('hi'), 'Kappa')), 'hi Kappa |');
      expect(_show(insertAtCaret(_value('hi '), 'Kappa')), 'hi Kappa |');
    });

    test('adds spaces only where the neighbouring character is none', () {
      expect(_show(insertAtCaret(_value('hi there', caret: 2), 'Kappa')), 'hi Kappa| there');
      expect(_show(insertAtCaret(_value('hi there', caret: 3), 'Kappa')), 'hi Kappa |there');
      expect(_show(insertAtCaret(_value('hi there', caret: 0), 'Kappa')), 'Kappa |hi there');
      expect(_show(insertAtCaret(_value('hithere', caret: 2), 'Kappa')), 'hi Kappa |there');
    });

    test('without a valid selection inserts at the start', () {
      expect(_show(insertAtCaret(_value('hi', selection: _invalid), 'Kappa')), 'Kappa |hi');
    });

    test('inserts at the base of a selected range and keeps the selected text', () {
      const selection = TextSelection(baseOffset: 0, extentOffset: 2);
      expect(_show(insertAtCaret(_value('hi', selection: selection), 'Kappa')), 'Kappa |hi');
      const reversed = TextSelection(baseOffset: 2, extentOffset: 0);
      expect(_show(insertAtCaret(_value('hi', selection: reversed), 'Kappa')), 'hi Kappa |');
    });
  });
}
