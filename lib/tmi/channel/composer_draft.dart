import 'dart:async';

import 'package:bloc/bloc.dart';

import 'messages/channel_message_chat.dart';

/// What the composer of a channel holds that isn't sent yet. Its state is the message being replied to, if any.
///
/// The tab view disposes a channel's view once it is off screen, so this lives on the [Channel] instead: the view
/// restores the text when it is built again and saves it back when it is disposed, and renders the reply from here.
/// Other widgets (the message sheet) set the reply or mention a user here instead of reaching into the view.
class ComposerDraft extends Cubit<ChannelMessageChat?> {
  ComposerDraft() : super(null);

  /// The text while no view is shown; the live view owns it otherwise.
  String text = '';

  /// Caret position in [text], or -1 for "at the end".
  int caret = -1;

  // Synchronous, so a view that is disposed right after the tap can't miss a mention it was listening for.
  final StreamController<String> _mentions = StreamController.broadcast(sync: true);

  /// Words to append to the composer's text, for the view that is shown. Without one, [mention] appends to [text].
  Stream<String> get mentions => _mentions.stream;

  /// Replies to [message] with the next message, or to nothing.
  void replyTo(ChannelMessageChat? message) {
    if (!isClosed) emit(message);
  }

  /// Puts `@login` at the end of the composer's text.
  void mention(String login) {
    final word = '@$login';
    if (_mentions.hasListener) {
      _mentions.add(word);
    } else {
      text = appendWordTo(text, word);
      caret = -1;
    }
  }

  void save({required String text, required int caret}) {
    this.text = text;
    this.caret = caret;
  }

  /// [caret] clamped to [text], with -1 (or anything invalid) meaning the end.
  int get restoredCaret => caret < 0 || caret > text.length ? text.length : caret;

  @override
  Future<void> close() async {
    await _mentions.close();
    return super.close();
  }
}

/// [text] with [word] appended as a new space-separated word, dropping empty words (repeated, leading and trailing
/// spaces).
String appendWordTo(String text, String word) => [...text.split(' '), word].where((w) => w.isNotEmpty).join(' ');
