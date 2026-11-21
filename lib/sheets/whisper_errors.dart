import 'package:flutter/material.dart';

import '../api/twitch/twitch.dart';
import '../l10n/app_localizations.dart';
import '../tmi/whispers/whispers.dart';
import 'login.dart';

/// Shows why a whisper couldn't be sent or opened, with a "Sign in" action when a new login fixes it.
void showWhisperError(ScaffoldMessengerState messenger, NavigatorState navigator, Object error) {
  final text = whisperErrorText(messenger.context, error);
  if (whisperErrorNeedsSignIn(error)) {
    showSignInSnackBar(messenger, navigator, text);
  } else {
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Whether signing in (again) fixes [error]: no login, or one from before ColdChat supported whispers.
bool whisperErrorNeedsSignIn(Object error) => error is WhisperUnavailableException;

/// Why a whisper couldn't be sent or opened, for the user.
String whisperErrorText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is WhisperUnavailableException) {
    return error.missingScope ? l10n.whisperNeedsScope : l10n.whisperNeedsLogin;
  }
  if (error is WhisperUserNotFoundException) return l10n.whisperUserNotFound;
  if (error is TwitchRequestException) return l10n.whisperFailed(error.message);
  return l10n.whisperFailed('$error');
}
