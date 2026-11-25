/// Translates regexes written for Chatty (Java's `java.util.regex`) or Chatterino (PCRE2) into Dart's syntax, which
/// is JavaScript's. People paste their trigger lists from those clients, and Dart rejects or misreads several things
/// both of them accept:
///
/// - inline flags such as `(?i)`, also mid-pattern: rewritten to scoped groups `(?i:…)`, which Dart supports for
///   `i`, `s` and `m`. The flags `u`, `U` and `d` only change Unicode or line-ending details and are dropped.
/// - possessive quantifiers (`a*+`) and atomic groups (`(?>…)`): Dart has neither, so they become plain greedy
///   quantifiers and non-capturing groups. That only changes how the engine backtracks, so a pattern can match a
///   little more often than in Java, never less.
/// - `\Q…\E`, `\A`, `\z`, `\Z`, `\h`, `\R`, `\e`, `\a`: Dart reads these as plain letters without complaint.
/// - `\p{…}`: POSIX classes like `\p{Alpha}` become ASCII sets; Unicode properties (`\p{L}`, `\p{IsLatin}`) turn on
///   Dart's Unicode mode, where Dart supports them.
/// - PCRE named groups `(?P<name>…)`, `(?'name'…)` and `(?P=name)`.
///
/// What still doesn't compile afterwards (e.g. comments mode `(?x)` or Unicode blocks `\p{InGreek}`) is left for the
/// caller to report as an invalid regex.
library;

/// [source] in Dart's syntax, and whether it has to be compiled with `unicode: true`.
({String pattern, bool unicode}) toDartRegex(String source) => _Translator(source).translate();

/// Java's POSIX character classes (US-ASCII only, like Java's default), as the inside of a character class.
const Map<String, String> _posixClasses = {
  'Lower': 'a-z',
  'Upper': 'A-Z',
  'ASCII': r'\x00-\x7F',
  'Alpha': 'a-zA-Z',
  'Digit': '0-9',
  'Alnum': 'a-zA-Z0-9',
  'Punct': r'!-\/:-@\[-`{-~',
  'Graph': '!-~',
  'Print': ' -~',
  'Blank': r' \t',
  'Cntrl': r'\x00-\x1F\x7F',
  'XDigit': '0-9a-fA-F',
  'Space': r' \t\n\x0B\f\r',
};

/// Horizontal whitespace (`\h` in Java and PCRE), as the inside of a character class.
const String _horizontalSpace = r'\t \xA0 ᠎ -   　';

/// Characters that may be escaped with a backslash in Dart's Unicode mode.
const String _syntaxCharacters = r'^$\.*+?()[]{}|/';

final RegExp _letterOrDigit = RegExp('[a-zA-Z0-9]');
final RegExp _inlineFlags = RegExp(r'\(\?([a-zA-Z]*(?:-[a-zA-Z]*)?)([:)])');
final RegExp _quantifierBraces = RegExp(r'\{\d+(?:,\d*)?\}');

class _Group {
  /// The scoped flag groups opened in this group, outermost first, e.g. `['i', 's']` for `(?i)a(?s)b`. They are
  /// closed before every `|` and the group's end and opened again after a `|`, because Java applies an inline flag
  /// to the rest of the enclosing group, alternatives included.
  final List<String> flags = [];
}

class _Translator {
  final String source;
  final StringBuffer out = StringBuffer();
  final List<_Group> groups = [_Group()];
  int i = 0;
  bool inClass = false;
  bool unicode = false;

  /// Whether the last thing written was a quantifier, so a following `+` makes it possessive.
  bool afterQuantifier = false;

  _Translator(this.source);

  ({String pattern, bool unicode}) translate() {
    while (i < source.length) {
      final char = source[i];
      if (char == r'\') {
        _escape();
        continue;
      }
      if (inClass) {
        if (char == ']') inClass = false;
        out.write(char);
        i++;
        continue;
      }
      if (afterQuantifier && char == '+') {
        // Possessive: drop the `+`, keep the greedy quantifier.
        afterQuantifier = false;
        i++;
        continue;
      }
      if (afterQuantifier && char == '?') {
        // Lazy quantifier.
        afterQuantifier = false;
        out.write(char);
        i++;
        continue;
      }
      afterQuantifier = false;
      switch (char) {
        case '[':
          inClass = true;
          out.write(char);
          i++;
          if (i < source.length && source[i] == '^') {
            out.write('^');
            i++;
          }
        case '(':
          _openGroup();
        case ')':
          _closeFlags(groups.last);
          if (groups.length > 1) groups.removeLast();
          out.write(char);
          i++;
        case '|':
          final group = groups.last;
          _closeFlags(group);
          out.write('|');
          for (final flags in group.flags) {
            out.write('(?$flags:');
          }
          i++;
        case '*' || '+' || '?':
          out.write(char);
          i++;
          afterQuantifier = true;
        case '{':
          final braces = _quantifierBraces.matchAsPrefix(source, i);
          if (braces != null) {
            out.write(braces[0]);
            i = braces.end;
            afterQuantifier = true;
          } else {
            // A literal brace, which Unicode mode wants escaped.
            out.write(r'\{');
            i++;
          }
        case '}' || ']':
          out.write('\\$char');
          i++;
        default:
          out.write(char);
          i++;
      }
    }
    for (final group in groups.reversed) {
      _closeFlags(group);
    }
    return (pattern: out.toString(), unicode: unicode);
  }

  void _closeFlags(_Group group) {
    out.write(')' * group.flags.length);
  }

  void _openGroup() {
    final rest = source.substring(i);
    final flagsMatch = _inlineFlags.matchAsPrefix(source, i);
    if (flagsMatch != null && (flagsMatch[1]!.isNotEmpty || flagsMatch[2] == ':')) {
      final flags = _dartFlags(flagsMatch[1]!);
      i = flagsMatch.end;
      if (flagsMatch[2] == ':') {
        out.write(flags == null || flags.isEmpty ? '(?:' : '(?$flags:');
        groups.add(_Group());
      } else if (flags == null) {
        // A flag Dart can't express, like comments mode: keep it so the pattern is reported as invalid.
        out.write(flagsMatch[0]);
      } else if (flags.isNotEmpty) {
        out.write('(?$flags:');
        groups.last.flags.add(flags);
      }
      return;
    }
    if (rest.startsWith('(?>')) {
      out.write('(?:');
      i += 3;
    } else if (rest.startsWith('(?P<')) {
      out.write('(?<');
      i += 4;
    } else if (rest.startsWith("(?'")) {
      final end = source.indexOf("'", i + 3);
      if (end < 0) {
        out.write(rest);
        i = source.length;
        return;
      }
      out.write('(?<${source.substring(i + 3, end)}>');
      i = end + 1;
    } else if (rest.startsWith('(?P=')) {
      final end = source.indexOf(')', i);
      if (end < 0) {
        out.write(rest);
        i = source.length;
        return;
      }
      out.write('\\k<${source.substring(i + 4, end)}>');
      i = end + 1;
      return;
    } else {
      out.write('(');
      i++;
    }
    groups.add(_Group());
  }

  /// The inline [flags] (like `iu` or `i-s`) reduced to what Dart's scoped groups support, an empty string when
  /// nothing is left, or null when a flag can't be expressed in Dart.
  String? _dartFlags(String flags) {
    final parts = flags.split('-');
    String? keep(String part) {
      final buffer = StringBuffer();
      for (final flag in part.split('')) {
        if ('ism'.contains(flag)) {
          if (!buffer.toString().contains(flag)) buffer.write(flag);
        } else if (!'uUd'.contains(flag)) {
          return null;
        }
      }
      return buffer.toString();
    }

    final on = keep(parts[0]);
    final off = parts.length > 1 ? keep(parts[1]) : '';
    if (on == null || off == null) return null;
    return off.isEmpty ? on : '$on-$off';
  }

  void _escape() {
    if (i + 1 >= source.length) {
      out.write(r'\');
      i++;
      return;
    }
    final char = source[i + 1];
    i += 2;
    afterQuantifier = false;
    switch (char) {
      case 'Q':
        final end = source.indexOf(r'\E', i);
        final literal = source.substring(i, end < 0 ? source.length : end);
        i = end < 0 ? source.length : end + 2;
        for (final c in literal.split('')) {
          out.write(_letterOrDigit.hasMatch(c) || c == ' ' ? c : _escapedLiteral(c));
        }
      case 'E':
        // A stray `\E` without `\Q` means nothing in Java.
        break;
      case 'A' when !inClass:
        out.write('^');
      case 'z' || 'Z' when !inClass:
        out.write(r'$');
      case 'h':
        out.write(inClass ? _horizontalSpace : '[$_horizontalSpace]');
      case 'H' when !inClass:
        out.write('[^$_horizontalSpace]');
      case 'R' when !inClass:
        out.write(r'(?:\r\n|[\n\x0B\f\r\x85  ])');
      case 'e':
        out.write(r'\x1B');
      case 'a':
        out.write(r'\x07');
      case 'p' || 'P':
        _property(negated: char == 'P');
      default:
        if (_letterOrDigit.hasMatch(char)) {
          out.write('\\$char');
        } else {
          // Java lets any punctuation be escaped; Dart's Unicode mode only allows syntax characters (and `-` in a
          // class). Escaping with `\x` keeps the character literal in both modes.
          out.write(_escapedLiteral(char));
        }
    }
  }

  /// [char], which isn't a letter or digit, written so it is literal in and outside a character class, in both modes.
  String _escapedLiteral(String char) {
    if (_syntaxCharacters.contains(char)) return '\\$char';
    final code = char.codeUnitAt(0);
    if (code > 0xFF) return '\\u${code.toRadixString(16).padLeft(4, '0')}';
    return '\\x${code.toRadixString(16).padLeft(2, '0')}';
  }

  /// A `\p` or `\P` (already consumed) and its name, `\pL` or `\p{Name}`.
  void _property({required bool negated}) {
    String name;
    if (i < source.length && source[i] == '{') {
      final end = source.indexOf('}', i);
      if (end < 0) {
        out.write('\\${negated ? 'P' : 'p'}');
        return;
      }
      name = source.substring(i + 1, end);
      i = end + 1;
    } else if (i < source.length) {
      name = source[i];
      i++;
    } else {
      out.write('\\${negated ? 'P' : 'p'}');
      return;
    }

    final posix = _posixClasses[name];
    if (posix != null) {
      if (!inClass) {
        out.write(negated ? '[^$posix]' : '[$posix]');
        return;
      }
      if (!negated) {
        out.write(posix);
        return;
      }
    }

    final dartName = _unicodeProperty(name);
    unicode = true;
    out.write('\\${negated ? 'P' : 'p'}{${dartName ?? name}}');
  }

  /// [name] as a Unicode property Dart knows, or null. Java writes scripts and binary properties with an `Is`
  /// prefix (`IsLatin`, `IsAlphabetic`); Dart wants `Script=Latin` and `Alphabetic`.
  String? _unicodeProperty(String name) {
    bool valid(String candidate) {
      try {
        RegExp('\\p{$candidate}', unicode: true);
        return true;
      } on FormatException {
        return false;
      }
    }

    final bare = name.startsWith('Is') ? name.substring(2) : name;
    for (final candidate in [name, bare, 'Script=$bare']) {
      if (valid(candidate)) return candidate;
    }
    return null;
  }
}
