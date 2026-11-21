import 'dart:math';

import 'package:flutter/services.dart';

import '../../tmi/channel/composer_draft.dart';

// Edits of the composer's text, as pure functions of its TextEditingValue.

/// Replaces the last space-separated word of [value] with [word] and a space, caret at the end. Used when an
/// autocompletion is tapped; where the caret was doesn't matter.
TextEditingValue completeLastWord(TextEditingValue value, String word) {
  final splits = value.text.split(' ');
  splits.removeLast();
  splits.add('$word ');
  return _caretAtEnd(splits.join(' '));
}

/// Appends [word] as a new space-separated word, dropping empty words (repeated, leading and trailing spaces), caret
/// at the end. Used to mention a user from the message sheet.
TextEditingValue appendWord(TextEditingValue value, String word) => _caretAtEnd(appendWordTo(value.text, word));

/// Inserts [url] in place of the selection (at the end without a valid one), with a space before it unless the text
/// up to the selection's end already ends with one, and a space after it. The caret goes after the inserted text.
TextEditingValue insertUploadedUrl(TextEditingValue value, String url) {
  final text = value.text;
  final selection = value.selection;
  final at = selection.isValid ? selection.end : text.length;
  final start = selection.isValid ? selection.start : at;

  final needsLeadingSpace = at > 0 && !text.substring(0, at).endsWith(' ');
  final insertion = '${needsLeadingSpace ? ' ' : ''}$url ';
  return TextEditingValue(
    text: text.replaceRange(start, at, insertion),
    selection: TextSelection.collapsed(offset: start + insertion.length),
  );
}

/// Inserts [insert] (from the emote picker) at the selection's base offset (the start without a valid selection),
/// with a space before and after it unless the neighbouring character already is one. A selected range is kept, not
/// replaced. The caret goes after the inserted text.
TextEditingValue insertAtCaret(TextEditingValue value, String insert) {
  final text = value.text;
  final cursorPosition = max(0, value.selection.baseOffset);
  if (text.isEmpty || cursorPosition >= text.length || text[cursorPosition] != ' ') {
    insert = '$insert ';
  }
  if (cursorPosition > 0 && text[cursorPosition - 1] != ' ') {
    insert = ' $insert';
  }
  return TextEditingValue(
    text: text.substring(0, cursorPosition) + insert + text.substring(cursorPosition),
    selection: TextSelection.collapsed(offset: cursorPosition + insert.length),
  );
}

TextEditingValue _caretAtEnd(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);
