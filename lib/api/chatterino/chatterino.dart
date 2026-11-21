import '../api_client.dart';
import '../json_isolate.dart';
import 'chatterino_badge.dart';

/// Chatterino's badges. No login.
class ChatterinoApi {
  final ApiClient _api;

  ChatterinoApi(this._api);

  /// The answer is `{"badges": [...]}`.
  Future<List<ChatterinoBadge>> badges() => _api.getJson(
    Uri.parse('https://api.chatterino.com/badges'),
    (json) => [
      for (final badge in ((json as JsonMap)['badges'] as List<dynamic>?) ?? const <dynamic>[])
        if (badge is Map<String, dynamic>) ChatterinoBadge.fromJson(badge),
    ],
  );
}
