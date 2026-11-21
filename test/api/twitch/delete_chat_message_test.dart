import 'package:coldchat/api/twitch/twitch.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

TokenData _tokenData() => TokenData(
  clientId: 'client-id-1',
  login: 'ronni',
  scopes: const [Twitch.deleteChatMessageScope],
  userId: '1337',
  expiresAt: null,
  accessToken: 'access-token-1',
);

Future<void> _delete(MockClient client, {String messageId = 'abc'}) => Twitch.deleteChatMessage(
  _tokenData(),
  broadcasterId: '12826',
  moderatorId: '1337',
  messageId: messageId,
  client: client,
);

void main() {
  test('sends a DELETE for exactly the one message, with the token', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('', 204);
    });

    await _delete(client, messageId: 'b34ccfc7-4977-403a-8a94-33c6bac34fb8');

    expect(requests, hasLength(1));
    final request = requests.single;
    expect(request.method, 'DELETE');
    expect(request.url.scheme, 'https');
    expect(request.url.host, 'api.twitch.tv');
    expect(request.url.path, '/helix/moderation/chat');
    expect(request.url.queryParameters, {
      'broadcaster_id': '12826',
      'moderator_id': '1337',
      'message_id': 'b34ccfc7-4977-403a-8a94-33c6bac34fb8',
    });
    expect(request.headers['Authorization'], 'Bearer access-token-1');
    expect(request.headers['Client-Id'], 'client-id-1');
  });

  test('an empty message id throws before any request, as Helix would delete the whole chat', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response('', 204);
    });

    await expectLater(_delete(client, messageId: ''), throwsArgumentError);
    expect(requests, 0);
  });

  test('a refused request throws a TwitchRequestException with the status and the reason Twitch gave', () async {
    final client = MockClient(
      (request) async => http.Response(
        '{"error":"Bad Request","status":400,"message":"You cannot delete the broadcaster\'s messages."}',
        400,
      ),
    );

    await expectLater(
      _delete(client),
      throwsA(
        isA<TwitchRequestException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', "You cannot delete the broadcaster's messages."),
      ),
    );
  });

  test('a response without a JSON body throws with the HTTP status as the reason', () async {
    final client = MockClient((request) async => http.Response('Bad Gateway', 502));

    await expectLater(
      _delete(client),
      throwsA(
        isA<TwitchRequestException>()
            .having((e) => e.statusCode, 'statusCode', 502)
            .having((e) => e.message, 'message', 'HTTP 502'),
      ),
    );
  });
}
