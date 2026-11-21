import 'dart:convert';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/tmi/moderation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../api/fake_api.dart';

TokenData _tokenData({List<String> scopes = const [HelixApi.deleteChatMessageScope, moderationScope]}) => TokenData(
  clientId: 'client-id-1',
  login: 'ronni',
  scopes: scopes,
  userId: '1337',
  expiresAt: null,
  accessToken: 'access-token-1',
);

/// Helix against a Twitch that answers with [response] (or fails with [error]), collecting the requests in
/// [requests].
HelixApi _helix({http.Response? response, Exception? error, List<http.Request>? requests}) => HelixApi(
  fakeApi(requests: requests, (request) async {
    if (error != null) throw error;
    return response ?? http.Response('', 204);
  }),
  () => null,
);

const _banResponse =
    '{"data":[{"broadcaster_id":"12826","moderator_id":"1337","user_id":"9001","created_at":"2026-11-21T20:00:00Z",'
    '"end_time":null}]}';

void main() {
  group('deleteMessageAs', () {
    Future<ModerationFailure?> delete(
      TokenData? tokenData, {
      http.Response? response,
      Exception? error,
      List<http.Request>? requests,
    }) => deleteMessageAs(
      tokenData,
      broadcasterId: '12826',
      messageId: 'b34ccfc7-4977-403a-8a94-33c6bac34fb8',
      helix: _helix(response: response, error: error, requests: requests),
    );

    test('deletes the message as the account itself', () async {
      final requests = <http.Request>[];

      expect(await delete(_tokenData(), requests: requests), isNull);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.queryParameters, {
        'broadcaster_id': '12826',
        'moderator_id': '1337',
        'message_id': 'b34ccfc7-4977-403a-8a94-33c6bac34fb8',
      });
    });

    test('without a token needs the scope and sends nothing', () async {
      final requests = <http.Request>[];

      expect(await delete(null, requests: requests), const ModerationNeedsScope());
      expect(requests, isEmpty);
    });

    test('a login without the delete scope needs the scope and sends nothing', () async {
      final requests = <http.Request>[];

      expect(
        await delete(_tokenData(scopes: const ['chat:read', 'chat:edit']), requests: requests),
        const ModerationNeedsScope(),
      );
      expect(requests, isEmpty);
    });

    test('a 401 from Twitch needs the scope', () async {
      final failure = await delete(
        _tokenData(),
        response: http.Response('{"error":"Unauthorized","status":401,"message":"Missing scope"}', 401),
      );

      expect(failure, const ModerationNeedsScope());
      expect(failure!.needsSignIn, isTrue);
    });

    test('another refusal carries the reason Twitch gave', () async {
      final failure = await delete(
        _tokenData(),
        response: http.Response(
          '{"error":"Bad Request","status":400,"message":"You cannot delete the broadcaster\'s messages."}',
          400,
        ),
      );

      expect(failure, const ModerationRequestFailed("You cannot delete the broadcaster's messages."));
      expect(failure!.needsSignIn, isFalse);
    });

    test('a network error carries the error', () async {
      final failure = await delete(_tokenData(), error: http.ClientException('Connection refused'));

      expect(failure, const ModerationRequestFailed('ClientException: Connection refused'));
    });
  });

  group('moderateAs', () {
    Future<ModerationFailure?> moderate(
      ModerationAction action, {
      TokenData? tokenData,
      String? broadcasterId = '12826',
      http.Response? response,
      Exception? error,
      List<http.Request>? requests,
    }) => moderateAs(
      tokenData,
      action,
      broadcasterId: broadcasterId,
      helix: _helix(response: response, error: error, requests: requests),
    );

    test('bans for good as the account itself', () async {
      final requests = <http.Request>[];

      final failure = await moderate(
        const ModerationBan('9001'),
        tokenData: _tokenData(),
        response: http.Response(_banResponse, 200),
        requests: requests,
      );

      expect(failure, isNull);
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, endsWith('/moderation/bans'));
      expect(requests.single.url.queryParameters, {'broadcaster_id': '12826', 'moderator_id': '1337'});
      expect(jsonDecode(requests.single.body), {
        'data': {'user_id': '9001'},
      });
    });

    test('times out for the duration in seconds', () async {
      final requests = <http.Request>[];

      final failure = await moderate(
        const ModerationTimeout('9001', Duration(minutes: 5)),
        tokenData: _tokenData(),
        response: http.Response(_banResponse, 200),
        requests: requests,
      );

      expect(failure, isNull);
      expect(jsonDecode(requests.single.body), {
        'data': {'user_id': '9001', 'duration': 300},
      });
    });

    test('unbans', () async {
      final requests = <http.Request>[];

      expect(await moderate(const ModerationUnban('9001'), tokenData: _tokenData(), requests: requests), isNull);

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.queryParameters, {
        'broadcaster_id': '12826',
        'moderator_id': '1337',
        'user_id': '9001',
      });
    });

    test('without a login, channel or user id needs a login and sends nothing', () async {
      final requests = <http.Request>[];

      expect(await moderate(const ModerationBan('9001'), requests: requests), const ModerationNeedsLogin());
      expect(
        await moderate(const ModerationBan('9001'), tokenData: _tokenData(), broadcasterId: null, requests: requests),
        const ModerationNeedsLogin(),
      );
      expect(
        await moderate(const ModerationBan('9001'), tokenData: _tokenData()..userId = null, requests: requests),
        const ModerationNeedsLogin(),
      );
      expect(requests, isEmpty);
    });

    test('without the scope needs the scope and sends nothing', () async {
      final requests = <http.Request>[];

      final failure = await moderate(
        const ModerationUnban('9001'),
        tokenData: _tokenData(scopes: const ['chat:read', 'chat:edit']),
        requests: requests,
      );

      expect(failure, const ModerationNeedsScope());
      expect(requests, isEmpty);
    });

    test('a refusal carries the reason Twitch gave, without offering to sign in', () async {
      final failure = await moderate(
        const ModerationBan('9001'),
        tokenData: _tokenData(),
        response: http.Response('{"error":"Bad Request","status":400,"message":"user is already banned"}', 400),
      );

      expect(failure, const ModerationRequestFailed('user is already banned'));
      expect(failure!.needsSignIn, isFalse);
    });

    test('a network error carries the error', () async {
      final failure = await moderate(
        const ModerationTimeout('9001', Duration(seconds: 1)),
        tokenData: _tokenData(),
        error: http.ClientException('Connection refused'),
      );

      expect(failure, const ModerationRequestFailed('ClientException: Connection refused'));
    });
  });
}
