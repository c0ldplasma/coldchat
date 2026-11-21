import 'package:coldchat/api/twitch/twitch.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/modal/whisper_errors.dart';
import 'package:coldchat/tmi/whispers/whispers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<AppLocalizations> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scaffoldMessengerKey: messengerKey,
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    return AppLocalizations.of(navigatorKey.currentContext!);
  }

  test('offer to sign in only when the login is missing or lacks the scope', () {
    expect(whisperErrorNeedsSignIn(WhisperUnavailableException(missingScope: true)), isTrue);
    expect(whisperErrorNeedsSignIn(WhisperUnavailableException(missingScope: false)), isTrue);
    expect(whisperErrorNeedsSignIn(WhisperUserNotFoundException()), isFalse);
    expect(whisperErrorNeedsSignIn(TwitchRequestException(401, 'Unauthorized')), isFalse);
    expect(whisperErrorNeedsSignIn(Exception('offline')), isFalse);
  });

  testWidgets('whisperErrorText says why for each error', (tester) async {
    final l10n = await pumpApp(tester);
    final context = navigatorKey.currentContext!;
    expect(whisperErrorText(context, WhisperUnavailableException(missingScope: true)), l10n.whisperNeedsScope);
    expect(whisperErrorText(context, WhisperUnavailableException(missingScope: false)), l10n.whisperNeedsLogin);
    expect(whisperErrorText(context, WhisperUserNotFoundException()), l10n.whisperUserNotFound);
    expect(whisperErrorText(context, TwitchRequestException(400, 'Too long')), l10n.whisperFailed('Too long'));
    expect(whisperErrorText(context, Exception('offline')), l10n.whisperFailed('Exception: offline'));
  });

  testWidgets('showWhisperError adds a "Sign in" action only when signing in fixes it', (tester) async {
    final l10n = await pumpApp(tester);

    showWhisperError(messengerKey.currentState!, navigatorKey.currentState!, WhisperUserNotFoundException());
    await tester.pumpAndSettle();
    expect(find.text(l10n.whisperUserNotFound), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);

    messengerKey.currentState!.removeCurrentSnackBar();
    showWhisperError(
      messengerKey.currentState!,
      navigatorKey.currentState!,
      WhisperUnavailableException(missingScope: true),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.whisperNeedsScope), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, l10n.signInAgain), findsOneWidget);
  });
}
