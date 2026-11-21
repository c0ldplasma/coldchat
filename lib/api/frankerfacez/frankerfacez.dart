import '../api_client.dart';
import '../json_isolate.dart';
import 'frankerfacez_badges.dart';
import 'frankerfacez_set.dart';
import 'frankerfacez_user.dart';

/// FrankerFaceZ's emotes and badges. No login.
class FfzApi {
  final ApiClient _api;

  FfzApi(this._api);

  Future<FrankerFaceZUser> user(String uid) =>
      _api.getJson(Uri.parse('https://api.frankerfacez.com/v1/room/id/$uid'), _user, inIsolate: true);

  Future<List<FrankerFaceZSet>> globalSets() =>
      _api.getJson(Uri.parse('https://api.frankerfacez.com/v1/set/global'), _globalSets, inIsolate: true);

  Future<FrankerFaceZBadges> badges() =>
      _api.getJson(Uri.parse('https://api.frankerfacez.com/v1/badges/ids'), _badges, inIsolate: true);

  // Static, so they can be sent to the isolate that decodes the response.
  static FrankerFaceZUser _user(dynamic json) => FrankerFaceZUser.fromJson(json as JsonMap);

  static List<FrankerFaceZSet> _globalSets(dynamic json) => [
    for (final setData in ((json as JsonMap)['sets'] as JsonMap).values) FrankerFaceZSet.fromJson(setData as JsonMap),
  ];

  static FrankerFaceZBadges _badges(dynamic json) => FrankerFaceZBadges.fromJson(json as JsonMap);
}
