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
}
