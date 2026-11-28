import 'package:bloc/bloc.dart';

/// The emote panel below the composer, which takes the keyboard's place.
enum EmotePanel {
  closed,

  /// Tapping an emote puts it into the message.
  open,

  /// Opened by long-pressing the emote button: tapping an emote makes it the button's icon.
  pickingButtonIcon,
}

/// Whether the emote panel is open, for the shown chat. The home page shows it in the keyboard's place and closes it
/// when another tab is shown.
class EmotePanelCubit extends Cubit<EmotePanel> {
  EmotePanelCubit() : super(EmotePanel.closed);

  bool get isOpen => state != EmotePanel.closed;

  /// Whether the last [hide] hands over to the keyboard: then the panel stays until the keyboard covers it, so the
  /// composer doesn't move, instead of sliding away.
  bool get keyboardNext => _keyboardNext;
  bool _keyboardNext = false;

  /// The emote button: opens the panel, or closes it when it is open.
  void toggle() => emit(isOpen ? EmotePanel.closed : EmotePanel.open);

  /// Long-pressing the emote button.
  void pickButtonIcon() => emit(EmotePanel.pickingButtonIcon);

  /// Closes the panel, e.g. when another tab is shown, or with [keyboardNext] when the text field gets the keyboard
  /// back.
  void hide({bool keyboardNext = false}) {
    if (!isOpen) return;
    _keyboardNext = keyboardNext;
    emit(EmotePanel.closed);
  }
}
