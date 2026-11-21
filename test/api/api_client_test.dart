import 'dart:async';
import 'dart:convert';

import 'package:coldchat/api/api_client.dart';
import 'package:coldchat/api/json_isolate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_api.dart';

final _url = Uri.parse('https://example.com/v1/things?secret=query');

// Static, so it can be sent to the decoding isolate.
List<String> _names(dynamic json) => [for (final thing in json as List<dynamic>) (thing as JsonMap)['name'] as String];

void main() {
  group('send', () {
    test('sends the method, headers and body and returns any status without throwing', () async {
      final requests = <http.Request>[];
      final api = fakeApi(requests: requests, (request) async => http.Response('nope', 500));

      final response = await api.send('PUT', _url, headers: {'X-Test': '1'}, body: 'raw');

      expect(response.statusCode, 500);
      expect(response.body, 'nope');
      final request = requests.single;
      expect(request.method, 'PUT');
      expect(request.url, _url);
      expect(request.headers['X-Test'], '1');
      expect(request.body, 'raw');
    });

    test('encodes json as the body with a JSON content type', () async {
      final requests = <http.Request>[];
      final api = fakeApi(requests: requests, (request) async => http.Response('', 204));

      await api.send(
        'POST',
        _url,
        json: {
          'message': 'hi ÄÖÜ',
          'n': [1, 2],
        },
      );

      expect(requests.single.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(requests.single.body), {
        'message': 'hi ÄÖÜ',
        'n': [1, 2],
      });
    });

    test('a request without a body has no content type', () async {
      final requests = <http.Request>[];
      final api = fakeApi(requests: requests, (request) async => http.Response('', 204));

      await api.send('POST', _url);

      expect(requests.single.headers.containsKey('content-type'), isFalse);
      expect(requests.single.bodyBytes, isEmpty);
    });

    test('times out after the default timeout', () async {
      final never = Completer<http.Response>();
      final api = ApiClient(
        client: MockClient((request) => never.future),
        timeout: const Duration(milliseconds: 10),
      );

      await expectLater(api.send('GET', _url), throwsA(isA<TimeoutException>()));
    });

    test('a timeout passed to the call wins over the default', () async {
      final api = ApiClient(
        client: MockClient(
          (request) => Future.delayed(const Duration(milliseconds: 50), () => http.Response('late', 200)),
        ),
        timeout: const Duration(milliseconds: 10),
      );

      expect((await api.send('GET', _url, timeout: const Duration(seconds: 5))).body, 'late');
      await expectLater(api.send('GET', _url), throwsA(isA<TimeoutException>()));
    });

    test('a network error comes through as it is', () async {
      final api = offlineApi();

      await expectLater(api.send('GET', _url), throwsA(isA<http.ClientException>()));
    });
  });

  group('request', () {
    test('returns a 2xx response', () async {
      final api = fakeApi((request) async => http.Response('', 204));

      expect((await api.request('DELETE', _url)).statusCode, 204);
    });

    test('a non-2xx response throws an ApiException with the JSON message', () async {
      final api = fakeApi(
        (request) async => http.Response('{"error":"Bad Request","status":400,"message":"Missing user_id"}', 400),
      );

      await expectLater(
        api.request('GET', _url),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Missing user_id')
              .having((e) => e.body, 'body', contains('Bad Request'))
              .having((e) => e.url, 'url', _url),
        ),
      );
    });

    test('without a message the JSON error is the message', () async {
      final api = fakeApi((request) async => http.Response('{"error":"Not Found"}', 404));

      await expectLater(
        api.request('GET', _url),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Not Found')),
      );
    });

    test('a body that is not a JSON object gives the HTTP status as the message', () async {
      final api = fakeApi((request) async => http.Response('<html>Bad Gateway</html>', 502));

      await expectLater(
        api.request('GET', _url),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.message, 'message', 'HTTP 502')
              .having((e) => e.body, 'body', '<html>Bad Gateway</html>'),
        ),
      );
    });

    test('the exception text leaves out the query', () {
      final exception = ApiException(401, 'invalid', '', _url);

      expect('$exception', 'ApiException(401) example.com/v1/things: invalid');
    });
  });

  group('getJson', () {
    const body = '[{"name":"Kappa"},{"name":"PogChamp ✨"}]';

    test('decodes UTF-8 JSON and maps it', () async {
      final api = fakeApi((request) async => http.Response.bytes(utf8.encode(body), 200));

      expect(await api.getJson(_url, _names), ['Kappa', 'PogChamp ✨']);
    });

    test('decodes on a background isolate the same way', () async {
      final api = fakeApi((request) async => http.Response.bytes(utf8.encode(body), 200));

      expect(await api.getJson(_url, _names, inIsolate: true), ['Kappa', 'PogChamp ✨']);
    });

    test('sends the headers and throws an ApiException for a non-2xx status', () async {
      final requests = <http.Request>[];
      final api = fakeApi(requests: requests, (request) async => http.Response('{"message":"gone"}', 410));

      await expectLater(
        api.getJson(_url, _names, headers: {'Accept': 'application/json'}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 410)),
      );
      expect(requests.single.method, 'GET');
      expect(requests.single.headers['Accept'], 'application/json');
    });

    test('a body that is not JSON throws a FormatException', () async {
      final api = fakeApi((request) async => http.Response('not json', 200));

      await expectLater(api.getJson(_url, _names), throwsFormatException);
    });
  });

  test('openClient hands out a new client for each call', () {
    var created = 0;
    final api = ApiClient(
      client: MockClient((request) async => http.Response('', 200)),
      newClient: () {
        created++;
        return MockClient((request) async => http.Response('', 200));
      },
    );

    final first = api.openClient();
    final second = api.openClient();

    expect(created, 2);
    expect(identical(first, second), isFalse);
  });
}
