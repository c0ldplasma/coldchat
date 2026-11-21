import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'json_isolate.dart';

/// A response whose status is outside 200–299.
class ApiException implements Exception {
  final int statusCode;

  /// The reason to show: the `message` (or `error`) of a JSON error body, as Twitch and most other APIs send one,
  /// otherwise `HTTP <status>`.
  final String message;

  /// The raw response body, for callers that need more than [message].
  final String body;

  /// What was requested. Only its host and path appear in [toString], never the query.
  final Uri url;

  ApiException(this.statusCode, this.message, this.body, this.url);

  factory ApiException.fromResponse(http.Response response, Uri url) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    return ApiException(
      response.statusCode,
      jsonMessage(body) ?? 'HTTP ${response.statusCode}',
      body,
      url,
    );
  }

  /// The `message` or else the `error` field of a JSON object [body], or null when there is none.
  static String? jsonMessage(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is! JsonMap) return null;
      final message = decoded['message'] ?? decoded['error'];
      return message == null ? null : '$message';
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'ApiException($statusCode) ${url.host}${url.path}: $message';
}

/// The one HTTP client of the app. Every request to Twitch and the emote, badge, history and emoji services goes
/// through it, so they share connections per host, a default [timeout], JSON decoding and the error type
/// [ApiException]. The service classes (`HelixApi`, `SevenTvApi`, …) add their base URL, headers and parsing on top.
///
/// Failed requests are logged in debug builds with their method, host, path and status only: never headers (they
/// carry tokens) or the query.
class ApiClient {
  /// How long a request may take, including reading the whole response, unless the call passes its own timeout.
  static const Duration defaultTimeout = Duration(seconds: 15);

  final http.Client _client;
  final http.Client Function() _newClient;
  final Duration timeout;

  /// [client] and [newClient] are replaceable for tests; by default they are the platform's client.
  ApiClient({http.Client? client, http.Client Function()? newClient, this.timeout = defaultTimeout})
    : _client = client ?? http.Client(),
      _newClient = newClient ?? http.Client.new;

  /// A client of its own for a request that is aborted by closing its client, like an upload the user cancels.
  /// The caller closes it.
  http.Client openClient() => _newClient();

  /// Sends a [method] request to [url] and returns the response whatever its status.
  ///
  /// [json] is encoded as the body with `Content-Type: application/json`; otherwise [body] is sent as it is. Throws
  /// a [TimeoutException] after [timeout] (default: [ApiClient.timeout]) and whatever the client throws for network
  /// errors (usually an [http.ClientException]).
  Future<http.Response> send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? json,
    String? body,
    Duration? timeout,
  }) async {
    final request = http.Request(method, url);
    if (headers != null) request.headers.addAll(headers);
    if (json != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(json);
    } else if (body != null) {
      request.body = body;
    }
    try {
      return await _client.send(request).then(http.Response.fromStream).timeout(timeout ?? this.timeout);
    } catch (e) {
      _log(method, url, e is TimeoutException ? 'timed out' : e.runtimeType.toString());
      rethrow;
    }
  }

  /// Like [send], but throws an [ApiException] unless the status is 2xx.
  Future<http.Response> request(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? json,
    String? body,
    Duration? timeout,
  }) async {
    final response = await send(method, url, headers: headers, json: json, body: body, timeout: timeout);
    if (response.statusCode < 200 || response.statusCode > 299) {
      _log(method, url, 'HTTP ${response.statusCode}');
      throw ApiException.fromResponse(response, url);
    }
    return response;
  }

  /// GETs [url] and returns [map] applied to the decoded JSON body. Throws an [ApiException] unless the status is
  /// 2xx.
  ///
  /// With [inIsolate], decoding and [map] run on a background isolate, for big responses (see
  /// [decodeJsonInIsolate]); [map] must then be a top-level or static function.
  Future<T> getJson<T>(
    Uri url,
    T Function(dynamic json) map, {
    Map<String, String>? headers,
    Duration? timeout,
    bool inIsolate = false,
  }) async {
    final response = await request('GET', url, headers: headers, timeout: timeout);
    return decode(response, map, inIsolate: inIsolate);
  }

  /// [map] applied to the JSON body of [response], decoded as UTF-8.
  static Future<T> decode<T>(http.Response response, T Function(dynamic json) map, {bool inIsolate = false}) async {
    if (inIsolate) return decodeJsonInIsolate(response.bodyBytes, map);
    return map(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  /// Closes the shared client. Only for tests and shutdown: every request afterwards fails.
  void close() => _client.close();

  static void _log(String method, Uri url, String reason) {
    if (kDebugMode) debugPrint('API: $method ${url.host}${url.path} failed: $reason');
  }
}
