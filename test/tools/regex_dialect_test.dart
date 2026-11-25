import 'package:coldchat/tools/regex_dialect.dart';
import 'package:flutter_test/flutter_test.dart';

/// [pattern] translated and compiled the way message triggers do.
RegExp compile(String pattern, {bool caseSensitive = true}) {
  final dart = toDartRegex(pattern);
  return RegExp(dart.pattern, caseSensitive: caseSensitive, unicode: dart.unicode);
}

void main() {
  test('leaves Dart-compatible patterns alone', () {
    for (final pattern in [
      r'\bhello\b',
      r'^hi\s+\w+$',
      '(a|b)+c',
      r'(?<name>x)\k<name>',
      r'(?<!a)b(?=c)',
      '[a-z]{2,3}?',
    ]) {
      expect(toDartRegex(pattern).pattern, pattern, reason: pattern);
      expect(toDartRegex(pattern).unicode, isFalse);
    }
  });

  group('inline flags', () {
    test('a leading (?i) makes the pattern case-insensitive', () {
      expect(toDartRegex('(?i)foo').pattern, '(?i:foo)');
      expect(compile('(?i)foo').hasMatch('FOO'), isTrue);
    });

    test('a flag mid-pattern applies to the rest of the group, alternatives included', () {
      final regex = compile('x(?i)b|c');
      expect(regex.hasMatch('xB'), isTrue);
      expect(regex.hasMatch('C'), isTrue);
      expect(regex.hasMatch('X'), isFalse);

      final grouped = compile('(a(?i)b|c)d');
      expect(grouped.hasMatch('aBd'), isTrue);
      expect(grouped.hasMatch('Cd'), isTrue);
      expect(grouped.hasMatch('cD'), isFalse);
    });

    test('drops the Unicode flags Chatty adds and keeps s and m', () {
      expect(toDartRegex('(?iu)foo').pattern, '(?i:foo)');
      expect(toDartRegex('(?U)foo').pattern, 'foo');
      expect(toDartRegex('(?s).').pattern, '(?s:.)');
      expect(toDartRegex('(?iu:foo)bar').pattern, '(?i:foo)bar');
      expect(compile('(?-i)foo', caseSensitive: false).hasMatch('FOO'), isFalse);
    });

    test('keeps flags Dart cannot express so the pattern is reported as invalid', () {
      expect(() => compile('(?x) a b'), throwsFormatException);
    });
  });

  test('possessive quantifiers and atomic groups become greedy ones', () {
    expect(toDartRegex('a*+b').pattern, 'a*b');
    expect(toDartRegex('a++').pattern, 'a+');
    expect(toDartRegex('a?+').pattern, 'a?');
    expect(toDartRegex('a{2,}+').pattern, 'a{2,}');
    expect(toDartRegex('a*?').pattern, 'a*?');
    expect(toDartRegex('(?>ab|a)c').pattern, '(?:ab|a)c');
    expect(compile(r'\w++!').hasMatch('wow!'), isTrue);
  });

  test(r'\Q…\E quotes a literal', () {
    final regex = compile(r'\Qa.b*\E+');
    expect(regex.hasMatch('a.b*'), isTrue);
    expect(regex.hasMatch('axbb'), isFalse);
    expect(compile(r'\Q(?i)').hasMatch('(?i)'), isTrue);
  });

  test(r'\A, \z and \Z anchor the message', () {
    final regex = compile(r'\Afoo\z');
    expect(regex.hasMatch('foo'), isTrue);
    expect(regex.hasMatch('A foo'), isFalse);
    expect(compile(r'bar\Z').hasMatch('foobar'), isTrue);
  });

  test(r'\h, \R, \e and \a', () {
    expect(compile(r'a\hb').hasMatch('a b'), isTrue);
    expect(compile(r'a\hb').hasMatch('ahb'), isFalse);
    expect(compile(r'a\Hb').hasMatch('axb'), isTrue);
    expect(compile(r'[\h,]').hasMatch('\t'), isTrue);
    expect(compile(r'a\Rb').hasMatch('a\r\nb'), isTrue);
    expect(compile(r'\e').hasMatch('\x1B'), isTrue);
  });

  group('character properties', () {
    test('POSIX classes are ASCII sets', () {
      expect(compile(r'^\p{Alpha}+$').hasMatch('abcXYZ'), isTrue);
      expect(compile(r'^\p{Alpha}+$').hasMatch('abc1'), isFalse);
      expect(compile(r'\P{Digit}').hasMatch('5'), isFalse);
      expect(compile(r'[\p{Punct}\d]').hasMatch('!'), isTrue);
      expect(toDartRegex(r'\p{Alpha}').unicode, isFalse);
    });

    test('Unicode properties turn on Unicode mode', () {
      expect(toDartRegex(r'\p{L}').unicode, isTrue);
      expect(compile(r'^\p{L}+$').hasMatch('äöü'), isTrue);
      expect(compile(r'\pL').hasMatch('é'), isTrue);
      expect(compile(r'\p{IsLatin}').hasMatch('a'), isTrue);
      expect(compile(r'\p{IsLatin}').hasMatch('я'), isFalse);
      expect(compile(r'\p{IsAlphabetic}').hasMatch('я'), isTrue);
    });

    test('escaped punctuation and literal braces still compile in Unicode mode', () {
      final regex = compile(r'\p{L}\-\_\@\#\:{x}]');
      expect(regex.hasMatch('a-_@#:{x}]'), isTrue);
      expect(compile(r'[\p{L}\-]+').hasMatch('a-b'), isTrue);
    });
  });

  test('PCRE named groups', () {
    expect(toDartRegex('(?P<n>a)(?P=n)').pattern, r'(?<n>a)\k<n>');
    expect(compile("(?'n'a)\\k<n>").hasMatch('aa'), isTrue);
  });

  test('never throws on broken input', () {
    for (final pattern in ['(', ')', r'\', r'\p', r'\p{', r'\Qabc', '(?', '[', "(?'n", '(?P=n', '{', '((?i)a']) {
      expect(() => toDartRegex(pattern), returnsNormally, reason: pattern);
    }
  });
}
