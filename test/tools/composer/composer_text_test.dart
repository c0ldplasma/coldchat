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

  group('insertWord', () {
    const url = 'https://i.example/a.png';

    test('into empty text adds only a space after it', () {
      expect(_show(insertWord(_value(''), 'Kappa')), 'Kappa |');
      expect(_show(insertWord(_value('', selection: _invalid), url)), '$url |');
    });

    test('at the end adds a space before it unless one is there, and one after it', () {
      expect(_show(insertWord(_value('hi'), 'Kappa')), 'hi Kappa |');
      expect(_show(insertWord(_value('hi '), 'Kappa')), 'hi Kappa |');
      expect(_show(insertWord(_value('hi there'), url)), 'hi there $url |');
    });

    test('at the caret adds spaces only where the neighbouring character is no whitespace', () {
      expect(_show(insertWord(_value('hi there', caret: 2), 'Kappa')), 'hi Kappa| there');
      expect(_show(insertWord(_value('hi there', caret: 3), 'Kappa')), 'hi Kappa |there');
      expect(_show(insertWord(_value('hi there', caret: 0), 'Kappa')), 'Kappa |hi there');
      expect(_show(insertWord(_value('hithere', caret: 2), 'Kappa')), 'hi Kappa |there');
      expect(_show(insertWord(_value('hi\nthere', caret: 3), 'Kappa')), 'hi\nKappa |there');
      expect(_show(insertWord(_value('hi there', caret: 2), url)), 'hi $url| there');
    });

    test('without a valid selection appends, for emotes and uploads alike', () {
      expect(_show(insertWord(_value('hi', selection: _invalid), 'Kappa')), 'hi Kappa |');
      expect(_show(insertWord(_value('hi', selection: _invalid), url)), 'hi $url |');
      expect(_show(insertWord(_value('hi ', selection: _invalid), url)), 'hi $url |');
      // A selection left over from longer text counts as none.
      expect(_show(insertWord(_value('hi', caret: 5), 'Kappa')), 'hi Kappa |');
    });

    test('replaces a selected range in either direction', () {
      const selection = TextSelection(baseOffset: 3, extentOffset: 5);
      expect(_show(insertWord(_value('ab cd ef', selection: selection), url)), 'ab $url| ef');
      const reversed = TextSelection(baseOffset: 5, extentOffset: 3);
      expect(_show(insertWord(_value('ab cd ef', selection: reversed), 'Kappa')), 'ab Kappa| ef');
      const withSpace = TextSelection(baseOffset: 3, extentOffset: 6);
      expect(_show(insertWord(_value('ab cd ef', selection: withSpace), url)), 'ab $url |ef');
    });

    test('decides on the leading space by the character before the selection start', () {
      const atEnd = TextSelection(baseOffset: 3, extentOffset: 5);
      expect(_show(insertWord(_value('ab cd', selection: atEnd), url)), 'ab $url |');
      const fromStart = TextSelection(baseOffset: 0, extentOffset: 2);
      expect(_show(insertWord(_value('ab cd', selection: fromStart), url)), '$url| cd');
      const midWord = TextSelection(baseOffset: 1, extentOffset: 4);
      expect(_show(insertWord(_value('ab cd', selection: midWord), 'Kappa')), 'a Kappa |d');
      const all = TextSelection(baseOffset: 0, extentOffset: 5);
      expect(_show(insertWord(_value('ab cd', selection: all), 'Kappa')), 'Kappa |');
    });
  });
}
