import 'package:coldchat/data/notifications_cubit.dart';
import 'package:coldchat/widgets/chat_avatar_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestNotificationsCubit extends NotificationsCubit {
  void setUnread(int unread) => emit(state.copyWith(unread: unread));
}

void main() {
  group('chatChromeAvatarVisible', () {
    test('hidden when the controls are hidden and nothing is unread', () {
      expect(chatChromeAvatarVisible(chromeShown: false, unread: 0), isFalse);
    });
    test('shown with the controls', () {
      expect(chatChromeAvatarVisible(chromeShown: true, unread: 0), isTrue);
    });
    test('shown on its own while there are unread notifications', () {
      expect(chatChromeAvatarVisible(chromeShown: false, unread: 1), isTrue);
      expect(chatChromeAvatarVisible(chromeShown: true, unread: 3), isTrue);
    });
  });

  group('ChatAvatarVisibility', () {
    late _TestNotificationsCubit cubit;
    late int taps;
    const avatar = Key('avatar');

    setUp(() {
      cubit = _TestNotificationsCubit();
      taps = 0;
    });
    tearDown(() => cubit.close());

    Future<void> pump(WidgetTester tester, {required bool chromeShown}) => tester.pumpWidget(
      BlocProvider<NotificationsCubit>.value(
        value: cubit,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ChatAvatarVisibility(
              chromeShown: chromeShown,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(key: avatar, width: 48, height: 48),
              ),
            ),
          ),
        ),
      ),
    );

    double opacity(WidgetTester tester) => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

    testWidgets('ignores taps while hidden', (tester) async {
      await pump(tester, chromeShown: false);
      await tester.tap(find.byKey(avatar), warnIfMissed: false);
      expect(taps, 0);
      expect(opacity(tester), 0.0);
    });

    testWidgets('accepts taps while the controls are shown', (tester) async {
      await pump(tester, chromeShown: true);
      await tester.tap(find.byKey(avatar));
      expect(taps, 1);
      expect(opacity(tester), 1.0);
    });

    testWidgets('shows and accepts taps as soon as a notification arrives, hides again once read', (tester) async {
      await pump(tester, chromeShown: false);
      cubit.setUnread(1);
      // The cubit's stream delivers the change after the first frame; settle until the widget has caught up.
      await tester.pumpAndSettle();
      expect(opacity(tester), 1.0);
      await tester.tap(find.byKey(avatar));
      expect(taps, 1);

      cubit.setUnread(0);
      await tester.pumpAndSettle();
      expect(opacity(tester), 0.0);
      await tester.tap(find.byKey(avatar), warnIfMissed: false);
      expect(taps, 1);
    });

    testWidgets('accepts taps again once the controls come back', (tester) async {
      await pump(tester, chromeShown: false);
      await pump(tester, chromeShown: true);
      await tester.tap(find.byKey(avatar));
      expect(taps, 1);
    });
  });
}
