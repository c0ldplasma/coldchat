import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../api/twitch/twitch_oauth.dart';
import '../components/modal.dart';
import '../l10n/app_localizations.dart';
import 'verify_token.dart';

/// Signs in to Twitch in the system's login sheet (ASWebAuthenticationSession on iOS, a Custom Tab on Android)
/// instead of an embedded web view, as RFC 8252 recommends for native apps: it shares the browser's Twitch login,
/// so a signed-in user only confirms, password managers and passkeys work, and ColdChat never sees the password.
/// The OAuth details (app, scopes, redirect, reading the answer) are in `lib/api/twitch/twitch_oauth.dart`.
///
/// Shared by the start screen, the "add account" tile and the expired-login banner.
Future<void> showTwitchLogin(BuildContext context) async {
  final navigator = Navigator.of(context);
  final state = randomOAuthState();
  final url = twitchAuthorizeUrl(state: state);

  final Uri callback;
  try {
    callback = Uri.parse(
      await FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: twitchCallbackScheme),
    );
  } on PlatformException catch (e) {
    // Closing the sheet is a deliberate choice, not an error.
    if (e.code == 'CANCELED') return;
    if (navigator.mounted) _showLoginFailed(navigator.context, e.message ?? e.code);
    return;
  }

  if (!navigator.mounted) return;
  switch (parseTwitchLoginCallback(callback, state: state)) {
    case TwitchLoginToken(:final accessToken):
      await Modal.show(
        context: navigator.context,
        child: VerifyTokenModal(token: accessToken, cookies: null),
      );
    case TwitchLoginDeclined():
      // Declining on Twitch's page is a deliberate choice too.
      return;
    case TwitchLoginFailed(:final reason):
      _showLoginFailed(navigator.context, reason);
  }
}

/// Shows [message], an error that signing in (again) fixes, with a "Sign in" action that starts the Twitch login.
///
/// [navigator] must outlive the snack bar: these errors usually show after a sheet was closed, so pass a navigator
/// captured before closing it, never the closed sheet's context. The new login becomes the active account
/// (`VerifyTokenModal`), so nothing else has to happen afterwards. [onSignIn] is only replaced in tests.
void showSignInSnackBar(
  ScaffoldMessengerState messenger,
  NavigatorState navigator,
  String message, {
  Future<void> Function(BuildContext context) onSignIn = showTwitchLogin,
}) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      // Long enough to reach the button, but still gone on its own instead of persisting like action snack bars do.
      duration: const Duration(seconds: 8),
      persist: false,
      action: SnackBarAction(
        label: AppLocalizations.of(messenger.context).signInAgain,
        onPressed: () {
          if (navigator.mounted) unawaited(onSignIn(navigator.context));
        },
      ),
    ),
  );
}

// A dialog rather than a snack bar, because a snack bar would sit behind the account sheet that may still be open.
void _showLoginFailed(BuildContext context, String reason) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(AppLocalizations.of(context).loginFailed),
    content: Text(reason),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context).close),
      ),
    ],
  ),
);
