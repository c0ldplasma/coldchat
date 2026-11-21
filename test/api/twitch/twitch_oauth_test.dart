import 'package:coldchat/api/twitch/twitch_oauth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('twitchAuthorizeUrl', () {
    test('asks Twitch for a token for every scope, with the relay redirect and the given state', () {
      final url = twitchAuthorizeUrl(state: 'abc123');

      expect(url.scheme, 'https');
      expect(url.host, 'id.twitch.tv');
      expect(url.path, '/oauth2/authorize');
      expect(url.queryParameters, {
        'client_id': twitchClientId,
        'redirect_uri': 'https://c0ldplasma.github.io/coldchat/auth.html',
        'response_type': 'token',
        'scope': twitchScopes.join(' '),
        'state': 'abc123',
        'force_verify': 'true',
      });
    });

    test('is the same URL the login built before the move', () {
      final before = Uri.https('id.twitch.tv', '/oauth2/authorize', {
        'client_id': twitchClientId,
        'redirect_uri': twitchRedirectUri,
        'response_type': 'token',
        'scope': twitchScopes.join(' '),
        'state': 's',
        'force_verify': 'true',
      });
      expect(twitchAuthorizeUrl(state: 's').toString(), before.toString());
    });

    test('starts at the endpoint the browser warm-up connects to', () {
      final url = twitchAuthorizeUrl(state: 's');
      expect('${url.origin}${url.path}', twitchAuthorizeEndpoint.toString());
    });

    test('includes the whisper scope that logins from before 2.3.0 lack', () {
      expect(twitchScopes, contains('user:manage:whispers'));
    });
  });

  group('randomOAuthState', () {
    test('is 32 hex characters and differs every time', () {
      final states = {for (var i = 0; i < 20; i++) randomOAuthState()};
      expect(states, hasLength(20));
      for (final state in states) {
        expect(state, matches(RegExp(r'^[0-9a-f]{32}$')));
      }
    });
  });

  group('parseTwitchLoginCallback', () {
    test('reads the access token from the fragment', () {
      final result = parseTwitchLoginCallback(
        Uri.parse('coldchat://auth#access_token=tok&scope=chat%3Aread&state=s&token_type=bearer'),
        state: 's',
      );
      expect(result, isA<TwitchLoginToken>().having((r) => r.accessToken, 'accessToken', 'tok'));
    });

    test('fails on a state that is not this login\'s', () {
      final result = parseTwitchLoginCallback(Uri.parse('coldchat://auth#access_token=tok&state=other'), state: 's');
      expect(result, isA<TwitchLoginFailed>().having((r) => r.reason, 'reason', 'state mismatch'));
    });

    test('fails on a missing state', () {
      final result = parseTwitchLoginCallback(Uri.parse('coldchat://auth#access_token=tok'), state: 's');
      expect(result, isA<TwitchLoginFailed>().having((r) => r.reason, 'reason', 'state mismatch'));
    });

    test('treats access_denied in the query as declined, not as an error', () {
      final result = parseTwitchLoginCallback(
        Uri.parse('coldchat://auth?error=access_denied&error_description=The+user+denied+you+access&state=s'),
        state: 's',
      );
      expect(result, isA<TwitchLoginDeclined>());
    });

    test('fails with the error description of any other error', () {
      final result = parseTwitchLoginCallback(
        Uri.parse(
          'coldchat://auth?error=redirect_mismatch&error_description=Parameter+redirect_uri+does+not+match&state=s',
        ),
        state: 's',
      );
      expect(
        result,
        isA<TwitchLoginFailed>().having((r) => r.reason, 'reason', 'Parameter redirect_uri does not match'),
      );
    });

    test('fails with the error code when there is no description', () {
      final result = parseTwitchLoginCallback(Uri.parse('coldchat://auth?error=server_error&state=s'), state: 's');
      expect(result, isA<TwitchLoginFailed>().having((r) => r.reason, 'reason', 'server_error'));
    });

    test('fails when there is neither a token nor an error', () {
      final result = parseTwitchLoginCallback(Uri.parse('coldchat://auth#state=s'), state: 's');
      expect(result, isA<TwitchLoginFailed>().having((r) => r.reason, 'reason', 'no access token'));
    });
  });
}
