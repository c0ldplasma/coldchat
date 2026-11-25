import 'message_trigger.dart';

/// One message trigger read from the trigger sheet's text field.
typedef MessageTriggerEntry = ({String pattern, bool enableRegex, bool caseSensitive});

/// What the message trigger field holds: one entry per line, or the 1-based [invalidLine] of the first regex that
/// doesn't compile.
typedef MessageTriggerInput = ({List<MessageTriggerEntry> entries, int? invalidLine});

/// Reads the message trigger field: one trigger per line, so a pattern can contain commas, spaces and `|`. Empty
/// lines and repeats are skipped. [enableRegex] and [caseSensitive] are the sheet's checkboxes.
///
/// A line may start with one of Chatty's match prefixes, so a list copied from Chatty keeps its meaning; the prefix
/// overrides the checkboxes (Chatty's regex prefixes are case-sensitive unless they end in `i`):
///
/// - `text:` plain text, `cs:` plain text, case-sensitive
/// - `w:` / `wcs:` whole word, `start:` / `startw:` at the start of the message
/// - `reg:` (or `re*:`) regex anywhere, `regi:` case-insensitive, `regw:` / `regwi:` between word boundaries,
///   `regm:` (or `re:`) the whole message
///
/// Chatty's other prefixes (`user:`, `chan:`, `config:`, …) aren't supported and stay part of the pattern.
MessageTriggerInput parseMessageTriggerInput(String text, {required bool enableRegex, required bool caseSensitive}) {
  final entries = <MessageTriggerEntry>[];
  int? invalidLine;
  final lines = text.split(RegExp(r'\r?\n'));
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) continue;
    final entry = _messageTriggerEntry(line, enableRegex: enableRegex, caseSensitive: caseSensitive);
    if (entry.pattern.isEmpty) continue;
    if (entry.enableRegex && !MessageTrigger.isValidRegex(entry.pattern)) {
      invalidLine ??= index + 1;
    }
    if (!entries.contains(entry)) entries.add(entry);
  }
  return (entries: entries, invalidLine: invalidLine);
}

MessageTriggerEntry _messageTriggerEntry(String line, {required bool enableRegex, required bool caseSensitive}) {
  final colon = line.indexOf(':');
  final prefix = colon < 0 ? null : line.substring(0, colon);
  final value = colon < 0 ? line : line.substring(colon + 1).trim();
  final escaped = RegExp.escape(value);
  return switch (prefix) {
    'text' => (pattern: value, enableRegex: false, caseSensitive: caseSensitive),
    'cs' => (pattern: value, enableRegex: false, caseSensitive: true),
    'w' => (pattern: '(?<!\\w)$escaped(?!\\w)', enableRegex: true, caseSensitive: false),
    'wcs' => (pattern: '(?<!\\w)$escaped(?!\\w)', enableRegex: true, caseSensitive: true),
    'start' => (pattern: '^$escaped', enableRegex: true, caseSensitive: false),
    'startw' => (pattern: '^$escaped(?!\\w)', enableRegex: true, caseSensitive: false),
    'reg' || 're*' => (pattern: value, enableRegex: true, caseSensitive: true),
    'regi' => (pattern: value, enableRegex: true, caseSensitive: false),
    'regw' => (pattern: '\\b(?:$value)\\b', enableRegex: true, caseSensitive: true),
    'regwi' => (pattern: '\\b(?:$value)\\b', enableRegex: true, caseSensitive: false),
    'regm' || 're' => (pattern: '^(?:$value)\$', enableRegex: true, caseSensitive: true),
    _ => (pattern: line, enableRegex: enableRegex, caseSensitive: caseSensitive),
  };
}

/// Reads the user trigger field: logins separated by commas, semicolons, spaces or new lines (a login has none of
/// them). A leading `@` and Chatty's `user:` prefix are dropped, and repeats are skipped ignoring case.
List<String> parseUserTriggerInput(String text) {
  final logins = <String>[];
  for (var login in text.split(RegExp(r'[\s,;]+'))) {
    if (login.startsWith('user:')) login = login.substring('user:'.length);
    if (login.startsWith('@')) login = login.substring(1);
    if (login.isEmpty) continue;
    if (logins.any((existing) => existing.toLowerCase() == login.toLowerCase())) continue;
    logins.add(login);
  }
  return logins;
}
