import 'package:coldchat/api/twitch/twitch.dart';
import 'package:coldchat/api/twitch/twitch_auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../fake_api.dart';

void main() {
  late List<http.Request> requests;

  TwitchAuthApi answering(http.Response response) =>
      TwitchAuthApi(fakeApi(requests: requests, (request) async => response));

  setUp(() => requests = []);

  test('reads the account, scopes and expiry of a valid token', () async {
    final before = DateTime.now();
    final auth = answering(
      http.Response(
        '{"client_id":"client-id-1","login":"ronni","scopes":["chat:read","chat:edit"],"user_id":"1337",'
        '"expires_in":3600}',
        200,
      ),
    );

    final tokenData = await auth.validateToken('access-token-1');

    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url, Uri.parse('https://id.twitch.tv/oauth2/validate'));
    expect(request.headers['Authorization'], 'Bearer access-token-1');
    expect(request.headers.containsKey('Client-Id'), isFalse);
    expect(tokenData.login, 'ronni');
    expect(tokenData.clientId, 'client-id-1');
    expect(tokenData.userId, '1337');
    expect(tokenData.scopes, ['chat:read', 'chat:edit']);
    expect(tokenData.accessToken, 'access-token-1');
    expect(tokenData.expiresAt!.isAfter(before.add(const Duration(seconds: 3599))), isTrue);
  });

  test('a token that never expires has no expiry', () async {
    final auth = answering(
      http.Response('{"client_id":"c","login":"ronni","scopes":[],"user_id":"1","expires_in":0}', 200),
    );

    expect((await auth.validateToken('t')).expiresAt, isNull);
  });

  test('a rejected token (401) throws a TwitchTokenInvalidException with the reason Twitch gave', () async {
    final auth = answering(http.Response('{"status":401,"message":"invalid access token"}', 401));

    await expectLater(
      auth.validateToken('t'),
      throwsA(isA<TwitchTokenInvalidException>().having((e) => e.message, 'message', 'invalid access token')),
    );
  });

  test('a 401 without a reason still throws a TwitchTokenInvalidException', () async {
    final auth = answering(http.Response('', 401));

    await expectLater(
      auth.validateToken('t'),
      throwsA(isA<TwitchTokenInvalidException>().having((e) => e.message, 'message', 'invalid access token')),
    );
  });

  test('another failure is a generic error, not a dead login', () async {
    final auth = answering(http.Response('{"status":500,"message":"oops"}', 500));

    await expectLater(
      auth.validateToken('t'),
      throwsA(
        isA<Exception>()
            .having((e) => e, 'not a dead login', isNot(isA<TwitchTokenInvalidException>()))
            .having((e) => '$e', 'text', 'Exception: Token validation failed (500): oops'),
      ),
    );
  });
}
