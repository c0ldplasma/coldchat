import 'package:coldchat/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// An [ApiClient] that answers every request with [handler] and records the requests in [requests].
ApiClient fakeApi(Future<http.Response> Function(http.Request request) handler, {List<http.Request>? requests}) =>
    ApiClient(
      client: MockClient((request) {
        requests?.add(request);
        return handler(request);
      }),
    );

/// An [ApiClient] for tests that make no request: every request fails as if offline.
ApiClient offlineApi() => fakeApi((request) async => throw http.ClientException('No network in tests', request.url));
