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

/// Inserts [word] (an emote from the picker or an uploaded file's link) in place of the selection, or at the end of
/// the text without a valid selection. A space goes before it unless it starts the text or follows whitespace, and
/// one after it unless whitespace follows, so it stays a word of its own (emote codes only render as one). The caret
/// goes after the inserted text.
TextEditingValue insertWord(TextEditingValue value, String word) {
  final text = value.text;
  final selection = value.selection;
  final valid = selection.isValid && selection.end <= text.length;
  final start = valid ? selection.start : text.length;
  final end = valid ? selection.end : text.length;

  final needsLeadingSpace = start > 0 && !_isWhitespace(text[start - 1]);
  final needsTrailingSpace = end == text.length || !_isWhitespace(text[end]);
  final insertion = '${needsLeadingSpace ? ' ' : ''}$word${needsTrailingSpace ? ' ' : ''}';
  return TextEditingValue(
    text: text.replaceRange(start, end, insertion),
    selection: TextSelection.collapsed(offset: start + insertion.length),
  );
}

bool _isWhitespace(String char) => char.trim().isEmpty;

TextEditingValue _caretAtEnd(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);
