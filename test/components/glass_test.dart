import 'dart:ui';

import 'package:coldchat/components/glass.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester, double strength) => tester.pumpWidget(
    MaterialApp(
      theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
      home: Center(
        child: Glass(strength: strength, child: const SizedBox(width: 100.0, height: 40.0)),
      ),
    ),
  );

  Color tint(WidgetTester tester) =>
      (tester
                  .widget<DecoratedBox>(
                    find.descendant(of: find.byType(Glass), matching: find.byType(DecoratedBox)).first,
                  )
                  .decoration
              as ShapeDecoration)
          .color!;

  testWidgets('fading in, the blur grows along with the tint instead of popping in at full strength', (tester) async {
    final full = ChatColors.from(ColdChatTheme.defaultAccent.colorScheme(Brightness.dark)).glass;

    await show(tester, 0.0);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tint(tester).a, 0.0);

    await show(tester, 0.5);
    expect(
      tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter,
      ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
    );
    expect(tint(tester).a, moreOrLessEquals(full.a * 0.5));

    await show(tester, 1.0);
    expect(
      tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter,
      ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
    );
    expect(tint(tester).a, moreOrLessEquals(full.a));
  });
}
