import 'dart:async';

import 'package:coldchat/components/modal.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Settings, the account sheet, the token input and token check close themselves and open the next sheet from their
  // own context in the same tap. That works because a popped sheet stays mounted for its closing animation; after an
  // await the context would be deactivated and Modal.show would throw.
  testWidgets('a sheet can close itself and open the next one from its own context', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Modal.show(
              context: context,
              child: Builder(
                builder: (sheetContext) => TextButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(Modal.show(context: sheetContext, child: const Text('second')));
                  },
                  child: const Text('next'),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('next'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('next'), findsNothing);
    expect(find.text('second'), findsOneWidget);
  });

  // showModalBottomSheet removes the status bar's padding from the sheet unless it's opened with useSafeArea; a tall
  // sheet like Settings then slid under the status bar.
  testWidgets('a tall sheet stays below the status bar, with a gap', (tester) async {
    const statusBar = 59.0;
    tester.view.padding = FakeViewPadding(top: statusBar * tester.view.devicePixelRatio);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Modal.show(
              context: context,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('header'),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [for (var i = 0; i < 100; i++) Text('entry $i')],
                    ),
                  ),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('header')).dy, greaterThanOrEqualTo(statusBar + Modal.topGap));

    // Only the entries scroll; the header stays where it is.
    final headerTop = tester.getTopLeft(find.text('header')).dy;
    await tester.drag(find.text('entry 5'), const Offset(0.0, -300.0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('header')).dy, headerTop);
    expect(find.text('entry 0'), findsNothing);
  });

  test('a sheet may take all the height below the status bar but the gap, never less than nothing', () {
    expect(modalMaxHeight(800.0), 800.0 - Modal.topGap);
    expect(modalMaxHeight(10.0), 0.0);
  });
}
