import 'package:coldchat/api/twitch/twitch.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/modal/message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

TokenData _tokenData({List<String> scopes = const [Twitch.deleteChatMessageScope]}) => TokenData(
  clientId: 'client-id-1',
  login: 'ronni',
  scopes: scopes,
  userId: '1337',
  expiresAt: null,
  accessToken: 'access-token-1',
);

/// Deletes as [tokenData] against a Twitch that answers with [response] (or fails with [error]), and collects the
/// requests in [requests].
Future<String?> _delete(
  TokenData? tokenData, {
  http.Response? response,
  Exception? error,
  List<http.Request>? requests,
}) => deleteMessageAs(
  tokenData,
  l10n,
  broadcasterId: '12826',
  messageId: 'b34ccfc7-4977-403a-8a94-33c6bac34fb8',
  client: MockClient((request) async {
    requests?.add(request);
    if (error != null) throw error;
    return response ?? http.Response('', 204);
  }),
);

void main() {
  test('deletes the message as the account itself and shows nothing', () async {
    final requests = <http.Request>[];

    expect(await _delete(_tokenData(), requests: requests), isNull);

    expect(requests, hasLength(1));
    expect(requests.single.url.queryParameters, {
      'broadcaster_id': '12826',
      'moderator_id': '1337',
      'message_id': 'b34ccfc7-4977-403a-8a94-33c6bac34fb8',
    });
  });

  test('without a token asks to sign in again and sends nothing', () async {
    final requests = <http.Request>[];

    expect(await _delete(null, requests: requests), l10n.deleteMessageNeedsScope);
    expect(requests, isEmpty);
  });

  test('a login without the delete scope asks to sign in again and sends nothing', () async {
    final requests = <http.Request>[];

    expect(
      await _delete(_tokenData(scopes: const ['chat:read', 'chat:edit']), requests: requests),
      l10n.deleteMessageNeedsScope,
    );
    expect(requests, isEmpty);
  });

  test('a 401 from Twitch asks to sign in again', () async {
    final text = await _delete(
      _tokenData(),
      response: http.Response('{"error":"Unauthorized","status":401,"message":"Missing scope"}', 401),
    );

    expect(text, l10n.deleteMessageNeedsScope);
  });

  test('another refusal shows the reason Twitch gave', () async {
    final text = await _delete(
      _tokenData(),
      response: http.Response(
        '{"error":"Bad Request","status":400,"message":"You cannot delete the broadcaster\'s messages."}',
        400,
      ),
    );

    expect(text, l10n.deleteMessageFailed("You cannot delete the broadcaster's messages."));
  });

  test('a network error shows the error', () async {
    final text = await _delete(_tokenData(), error: http.ClientException('Connection refused'));

    expect(text, l10n.deleteMessageFailed('ClientException: Connection refused'));
  });
}
