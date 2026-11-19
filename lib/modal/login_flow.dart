import 'dart:math';

import 'package:coldchat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '/components/modal.dart';
import 'verify_token.dart';

/// ColdChat's own Twitch app (dev.twitch.tv console). Public client, implicit grant: the client id isn't a secret,
/// it's part of every login URL.
const String twitchClientId = 'y05nqtxmuntv88n98uhfz4sfpr0u17';

/// The scheme the system login session hands back to ColdChat (`coldchat://auth…`). Android routes it to
/// flutter_web_auth_2's CallbackActivity (AndroidManifest.xml); iOS needs no setup for a custom scheme.
const String _callbackScheme = 'coldchat';

/// Registered in the Twitch console, exactly, including the path. A tiny page on ColdChat's website
/// (`docs/auth.html`) that forwards Twitch's answer to `coldchat://auth`, because Twitch only redirects to web
/// addresses. The token is in the URL fragment, which browsers never send to the server.
const String _redirectUri = 'https://c0ldplasma.github.io/coldchat/auth.html';

const List<String> _scopes = [
  // Chat
  'chat:edit',
  'chat:read',
  'channel:moderate',
  'channel:read:redemptions',
  'moderator:manage:automod',
  'channel:manage:broadcast',
  // Whispers
  'whispers:read',
  'whispers:edit',
  'user:manage:whispers',
  // Sub emotes
  'user_subscriptions',
  // Blocked users
  'user_blocks_edit',
  'user_blocks_read',
  'user:read:blocked_users',
  'user:manage:blocked_users',
  // Raids
  'channel_editor',
];

/// Signs in to Twitch in the system's login sheet (ASWebAuthenticationSession on iOS, a Custom Tab on Android)
/// instead of an embedded web view, as RFC 8252 recommends for native apps: it shares the browser's Twitch login,
/// so a signed-in user only confirms, password managers and passkeys work, and ColdChat never sees the password.
///
/// Shared by the start screen, the "add account" tile and the expired-login banner.
Future<void> showTwitchLogin(BuildContext context) async {
  final navigator = Navigator.of(context);
  final state = _randomState();
  final url = Uri.https('id.twitch.tv', '/oauth2/authorize', {
    'client_id': twitchClientId,
    'redirect_uri': _redirectUri,
    'response_type': 'token',
    'scope': _scopes.join(' '),
    'state': state,
    // Always show Twitch's confirmation with its "Not you?" link, so adding a second account doesn't silently
    // reuse the one the browser is signed in to.
    'force_verify': 'true',
  });

  final Uri result;
  try {
    result = Uri.parse(await FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: _callbackScheme));
  } on PlatformException catch (e) {
    // Closing the sheet is a deliberate choice, not an error.
    if (e.code == 'CANCELED') return;
    if (navigator.mounted) _showLoginFailed(navigator.context, e.message ?? e.code);
    return;
  }

  // Twitch puts a token in the fragment and an error in the query; the relay page passes both on unchanged.
  final fragment = Uri.splitQueryString(result.fragment);
  final params = {...result.queryParameters, ...fragment};
  if (!navigator.mounted) return;
  if (params['state'] != state) {
    // Not the answer to this request.
    _showLoginFailed(navigator.context, 'state mismatch');
    return;
  }
  final error = params['error'];
  if (error != null) {
    // Declining on Twitch's page is a deliberate choice too.
    if (error != 'access_denied') _showLoginFailed(navigator.context, params['error_description'] ?? error);
    return;
  }
  final accessToken = params['access_token'];
  if (accessToken == null) {
    _showLoginFailed(navigator.context, 'no access token');
    return;
  }
  await Modal.show(
    context: navigator.context,
    child: VerifyTokenModal(token: accessToken, cookies: null),
  );
}

String _randomState() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

// A dialog rather than a snack bar, because a snack bar would sit behind the account sheet that may still be open.
void _showLoginFailed(BuildContext context, String reason) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(AppLocalizations.of(context)!.loginFailed),
    content: Text(reason),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context)!.close),
      ),
    ],
  ),
);
