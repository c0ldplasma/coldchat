import 'package:http/http.dart' as http;

import '../json_isolate.dart';
import 'frankerfacez_badges.dart';
import 'frankerfacez_set.dart';
import 'frankerfacez_user.dart';

class FrankerFaceZ {
  static Future<FrankerFaceZUser> user(String uid) async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/room/id/$uid'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => FrankerFaceZUser.fromJson(json as JsonMap));
  }

  static Future<List<FrankerFaceZSet>> globalSets() async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/set/global'));
    return decodeJsonInIsolate(
      response.bodyBytes,
      (json) => [
        for (final setData in ((json as JsonMap)['sets'] as JsonMap).values)
          FrankerFaceZSet.fromJson(setData as JsonMap),
      ],
    );
  }

  static Future<FrankerFaceZBadges> badges() async {
    final response = await http.get(Uri.parse('https://api.frankerfacez.com/v1/badges/ids'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => FrankerFaceZBadges.fromJson(json as JsonMap));
  }
}
