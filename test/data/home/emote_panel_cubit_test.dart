import 'package:coldchat/data/home/emote_panel_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EmotePanelCubit panel;

  setUp(() => panel = EmotePanelCubit());
  tearDown(() => panel.close());

  test('starts closed', () {
    expect(panel.state, EmotePanel.closed);
    expect(panel.isOpen, isFalse);
  });

  test('the emote button opens and closes the panel', () {
    panel.toggle();
    expect(panel.state, EmotePanel.open);
    expect(panel.isOpen, isTrue);

    panel.toggle();
    expect(panel.state, EmotePanel.closed);
  });

  test('a long press opens it for picking the button icon, and a tap then closes it', () {
    panel.pickButtonIcon();
    expect(panel.state, EmotePanel.pickingButtonIcon);
    expect(panel.isOpen, isTrue);

    panel.toggle();
    expect(panel.state, EmotePanel.closed);
  });

  test('hide closes from any state and does nothing when closed', () async {
    final states = <EmotePanel>[];
    final subscription = panel.stream.listen(states.add);

    panel.hide();
    panel.pickButtonIcon();
    panel.hide();
    panel.hide();
    await pumpEventQueue();

    expect(states, [EmotePanel.pickingButtonIcon, EmotePanel.closed]);
    await subscription.cancel();
  });

  test('remembers whether the keyboard takes over from the panel', () {
    panel.toggle();
    panel.hide(keyboardNext: true);
    expect(panel.keyboardNext, isTrue);

    panel.toggle();
    panel.hide();
    expect(panel.keyboardNext, isFalse);
  });
}
