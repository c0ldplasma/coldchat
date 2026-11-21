import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/modal/login_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showSignInSnackBar', () {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final navigatorKey = GlobalKey<NavigatorState>();

    Future<void> pumpApp(WidgetTester tester, {Widget body = const SizedBox()}) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: messengerKey,
        navigatorKey: navigatorKey,
        home: Scaffold(body: body),
      ),
    );

    testWidgets('shows the message with a "Sign in" action for 8 seconds', (tester) async {
      await pumpApp(tester);
      showSignInSnackBar(messengerKey.currentState!, navigatorKey.currentState!, 'Sign in again to do this.');
      await tester.pumpAndSettle();

      expect(find.text('Sign in again to do this.'), findsOneWidget);
      final l10n = AppLocalizations.of(navigatorKey.currentContext!);
      expect(find.widgetWithText(SnackBarAction, l10n.signInAgain), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 8));
      expect(snackBar.persist, isFalse);

      // Unlike a default snack bar with an action, it goes away on its own.
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('tapping the action starts the login with a mounted context', (tester) async {
      await pumpApp(tester);
      final contexts = <BuildContext>[];
      showSignInSnackBar(
        messengerKey.currentState!,
        navigatorKey.currentState!,
        'message',
        onSignIn: (context) async => contexts.add(context),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();

      expect(contexts, hasLength(1));
      expect(contexts.single.mounted, isTrue);
      expect(Navigator.of(contexts.single), same(navigatorKey.currentState));
    });

    testWidgets('does nothing once the navigator is gone', (tester) async {
      // A navigator that is removed while the snack bar is still showing, like a closed sheet's would be.
      final innerKey = GlobalKey<NavigatorState>();
      await pumpApp(
        tester,
        body: Navigator(
          key: innerKey,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        ),
      );
      final navigator = innerKey.currentState!;
      var calls = 0;
      showSignInSnackBar(messengerKey.currentState!, navigator, 'message', onSignIn: (_) async => calls++);
      await tester.pumpAndSettle();

      await pumpApp(tester);
      await tester.pumpAndSettle();
      expect(navigator.mounted, isFalse);

      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();
      expect(calls, 0);
    });
  });
}
