import 'dart:math';

// How ColdChat asks Twitch for a login: its app, scopes and redirect, the authorize URL and reading the answer.
// The login itself runs in the system's login sheet; that part is `showTwitchLogin` in `lib/sheets/login.dart`.

/// ColdChat's own Twitch app (dev.twitch.tv console). Public client, implicit grant: the client id isn't a secret,
/// it's part of every login URL.
const String twitchClientId = 'y05nqtxmuntv88n98uhfz4sfpr0u17';

/// The scheme the system login session hands back to ColdChat (`coldchat://auth…`). Android routes it to
/// flutter_web_auth_2's CallbackActivity (AndroidManifest.xml); iOS needs no setup for a custom scheme.
const String twitchCallbackScheme = 'coldchat';

/// Registered in the Twitch console, exactly, including the path. A tiny page on ColdChat's website
/// (`docs/auth.html`) that forwards Twitch's answer to `coldchat://auth`, because Twitch only redirects to web
/// addresses. The token is in the URL fragment, which browsers never send to the server.
const String twitchRedirectUri = 'https://c0ldplasma.github.io/coldchat/auth.html';

const List<String> twitchScopes = [
  // Chat
  'chat:edit',
  'chat:read',
  'channel:moderate',
  'channel:read:redemptions',
  'moderator:manage:automod',
  'moderator:manage:chat_messages',
  // Ban, time out and unban from the user card
  'moderator:manage:banned_users',
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

/// Twitch's authorize endpoint, where every login starts.
final Uri twitchAuthorizeEndpoint = Uri.https('id.twitch.tv', '/oauth2/authorize');

/// A random `state` for one login: 16 random bytes as hex. The answer has to carry it back.
String randomOAuthState() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// The URL that asks Twitch for a token for [twitchScopes] (implicit grant, `response_type=token`).
Uri twitchAuthorizeUrl({required String state}) => twitchAuthorizeEndpoint.replace(
  queryParameters: {
    'client_id': twitchClientId,
    'redirect_uri': twitchRedirectUri,
    'response_type': 'token',
    'scope': twitchScopes.join(' '),
    'state': state,
    // Always show Twitch's confirmation with its "Not you?" link, so adding a second account doesn't silently
    // reuse the one the browser is signed in to.
    'force_verify': 'true',
  },
);

/// What Twitch answered to a login, read by [parseTwitchLoginCallback].
sealed class TwitchLoginResult {
  const TwitchLoginResult();
}

/// Twitch gave an access token.
class TwitchLoginToken extends TwitchLoginResult {
  final String accessToken;

  const TwitchLoginToken(this.accessToken);
}

/// The user declined on Twitch's page, a deliberate choice rather than an error.
class TwitchLoginDeclined extends TwitchLoginResult {
  const TwitchLoginDeclined();
}

/// The login failed; [reason] is shown to the user as it is.
class TwitchLoginFailed extends TwitchLoginResult {
  final String reason;

  const TwitchLoginFailed(this.reason);
}

/// Reads the `coldchat://auth…` URL the login sheet returned for the login started with [state].
TwitchLoginResult parseTwitchLoginCallback(Uri callback, {required String state}) {
  // Twitch puts a token in the fragment and an error in the query; the relay page passes both on unchanged.
  final fragment = Uri.splitQueryString(callback.fragment);
  final params = {...callback.queryParameters, ...fragment};
  // Not the answer to this request.
  if (params['state'] != state) return const TwitchLoginFailed('state mismatch');
  final error = params['error'];
  if (error != null) {
    if (error == 'access_denied') return const TwitchLoginDeclined();
    return TwitchLoginFailed(params['error_description'] ?? error);
  }
  final accessToken = params['access_token'];
  if (accessToken == null) return const TwitchLoginFailed('no access token');
  return TwitchLoginToken(accessToken);
}
