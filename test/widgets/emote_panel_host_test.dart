import 'package:coldchat/data/home/emote_panel_cubit.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:coldchat/widgets/emote_panel_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EmotePanelCubit panel;
  late List<double> saved;

  setUp(() {
    panel = EmotePanelCubit();
    saved = [];
  });
  tearDown(() => panel.close());

  /// The host over a page that only reports the keyboard inset it is told to avoid, which is what moves the
  /// composer. No chat is shown, so the panel itself isn't drawn; its room is.
  Future<void> showHost(WidgetTester tester, {double? savedKeyboardHeight}) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1206.0, 2622.0);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<EmotePanelCubit>.value(
        value: panel,
        child: MaterialApp(
          theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
          home: EmotePanelHost(
            channel: () => null,
            savedKeyboardHeight: savedKeyboardHeight,
            onKeyboardHeight: saved.add,
            child: Builder(builder: (context) => const SizedBox.expand(key: Key('page'))),
          ),
        ),
      ),
    );
  }

  /// The bottom inset the page below the host avoids: where the composer sits.
  double avoided(WidgetTester tester) => MediaQuery.viewInsetsOf(tester.element(find.byKey(const Key('page')))).bottom;

  Future<void> keyboard(WidgetTester tester, double height) async {
    tester.view.viewInsets = FakeViewPadding(bottom: height * 3.0);
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> frames(WidgetTester tester, [int count = 20]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('the panel takes the saved keyboard height from the start', (tester) async {
    await showHost(tester, savedKeyboardHeight: 336.0);

    panel.toggle();
    await frames(tester);

    expect(avoided(tester), moreOrLessEquals(336.0));
  });

  testWidgets('a panel taller than the keyboard lets it in without a jump, and learns its height', (tester) async {
    // Saved for another keyboard, or guessed: taller than the one that comes.
    await showHost(tester, savedKeyboardHeight: 400.0);
    panel.toggle();
    await frames(tester);
    expect(avoided(tester), moreOrLessEquals(400.0));

    // Tapping into the message field: the keyboard rises over the panel and stops at 336.
    panel.hide(keyboardNext: true);
    for (final height in [100.0, 200.0, 300.0, 336.0]) {
      await keyboard(tester, height);
      expect(avoided(tester), moreOrLessEquals(400.0), reason: 'keyboard at $height');
    }

    // Once it holds still, the panel goes right away (not after a timeout), moving the composer down smoothly onto
    // the keyboard, never below it.
    var previous = avoided(tester);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final now = avoided(tester);
      expect(now, lessThanOrEqualTo(previous + 0.01));
      expect(now, greaterThanOrEqualTo(336.0 - 0.01));
      previous = now;
    }
    expect(avoided(tester), moreOrLessEquals(336.0));
    expect(saved, [336.0]);

    // Next time the panel fits the keyboard exactly.
    panel.toggle();
    await frames(tester);
    expect(avoided(tester), moreOrLessEquals(336.0));
  });

  testWidgets('a keyboard opening on its own teaches the panel its height', (tester) async {
    await showHost(tester);

    for (final height in [100.0, 200.0, 291.0]) {
      await keyboard(tester, height);
    }
    await frames(tester, 10);

    expect(saved, [291.0]);
  });

  testWidgets('opening the panel from the keyboard takes the keyboard\'s height of that moment', (tester) async {
    // Saved for a keyboard taller than this one: the composer would jump up.
    await showHost(tester, savedKeyboardHeight: 400.0);
    for (final height in [100.0, 200.0, 336.0]) {
      await keyboard(tester, height);
    }
    // Before the keyboard counts as settled.
    await tester.pump(const Duration(milliseconds: 16));

    panel.toggle();
    await tester.pump();
    expect(avoided(tester), moreOrLessEquals(336.0));

    // The keyboard slides away behind the panel; the composer stays.
    for (final height in [200.0, 100.0, 0.0]) {
      await keyboard(tester, height);
      expect(avoided(tester), moreOrLessEquals(336.0), reason: 'keyboard at $height');
    }
    await frames(tester);
    expect(saved, contains(336.0));
  });
}
