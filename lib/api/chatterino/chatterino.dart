import '../api_client.dart';
import '../json_isolate.dart';
import 'chatterino_badge.dart';

/// Chatterino's badges. No login.
class ChatterinoApi {
  final ApiClient _api;

  ChatterinoApi(this._api);

  Future<List<ChatterinoBadge>> badges() => _api.getJson(
    Uri.parse('https://api.chatterino.com/badges'),
    (json) => [for (final badge in json as List<dynamic>) ChatterinoBadge.fromJson(badge as JsonMap)],
  );
}
