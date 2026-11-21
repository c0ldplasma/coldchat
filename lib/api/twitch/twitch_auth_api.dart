import '../../data/twitch/token_data.dart';
import '../api_client.dart';
import '../json_isolate.dart';
import 'twitch.dart';

/// Twitch's OAuth server (`https://id.twitch.tv/oauth2`).
class TwitchAuthApi {
  final ApiClient _api;

  TwitchAuthApi(this._api);

  /// What Twitch knows about [token]: its account, scopes and expiry.
  ///
  /// Throws a [TwitchTokenInvalidException] when Twitch rejects the token (401), so callers can react to an expired
  /// login, and a plain [Exception] for any other refusal.
  Future<TokenData> validateToken(String token) async {
    final JsonMap responseJson;
    try {
      responseJson = await _api.getJson(
        Uri.parse('https://id.twitch.tv/oauth2/validate'),
        (json) => json as JsonMap,
        headers: {'Authorization': 'Bearer $token'},
      );
    } on ApiException catch (e) {
      // A rejected token answers 401 with {status, message} and no login/client_id.
      if (e.statusCode == 401) {
        throw TwitchTokenInvalidException(ApiException.jsonMessage(e.body) ?? 'invalid access token');
      }
      throw Exception('Token validation failed (${e.statusCode}): ${ApiException.jsonMessage(e.body)}');
    }
    return TokenData(
      clientId: responseJson['client_id'] as String?,
      login: responseJson['login'] as String,
      scopes: List<String>.from(responseJson['scopes'] as List<dynamic>? ?? <dynamic>[]),
      userId: responseJson['user_id'] as String?,
      expiresAt: responseJson['expires_in'] == 0
          ? null
          : DateTime.now().add(
              Duration(seconds: responseJson['expires_in'] as int),
            ),
      accessToken: token,
    );
  }
}
