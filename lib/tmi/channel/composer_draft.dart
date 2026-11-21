import 'messages/channel_message_chat.dart';

/// What the composer of a channel holds that isn't sent yet.
///
/// The tab view disposes a channel's view once it is off screen, so this lives on the [Channel] instead: the view
/// restores it when it is built again and saves it back when it is disposed.
class ComposerDraft {
  String text = '';

  /// Caret position in [text], or -1 for "at the end".
  int caret = -1;

  ChannelMessageChat? reply;

  void save({required String text, required int caret, required ChannelMessageChat? reply}) {
    this.text = text;
    this.caret = caret;
    this.reply = reply;
  }

  /// [caret] clamped to [text], with -1 (or anything invalid) meaning the end.
  int get restoredCaret => caret < 0 || caret > text.length ? text.length : caret;
}
