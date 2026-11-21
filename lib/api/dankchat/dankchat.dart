import '../api_client.dart';
import '../json_isolate.dart';
import 'dankchat_badge.dart';

/// DankChat's badges. No login.
class DankChatApi {
  final ApiClient _api;

  DankChatApi(this._api);

  Future<List<DankChatBadge>> badges() => _api.getJson(
    Uri.parse('https://flxrs.com/api/badges'),
    (json) => [for (final badge in json as List<dynamic>) DankChatBadge.fromJson(badge as JsonMap)],
  );
}
