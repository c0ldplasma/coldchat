import 'package:http/http.dart' as http;

import '../json_isolate.dart';
import 'betterttv_badge.dart';
import 'betterttv_emote.dart';
import 'betterttv_user.dart';

class BetterTTV {
  static Future<List<BetterTTVEmote>> globalEmotes() async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/emotes/global'));
    return decodeJsonInIsolate(
      response.bodyBytes,
      (json) => [for (final emote in json as List<dynamic>) BetterTTVEmote.fromJson(emote as JsonMap)],
    );
  }

  static Future<BetterTTVUser?> user(String uid) async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/users/twitch/$uid'));
    return decodeJsonInIsolate(response.bodyBytes, (json) {
      final data = json as JsonMap;
      return data['id'] == null ? null : BetterTTVUser.fromJson(data);
    });
  }

  static Future<List<BetterTTVBadge>> badges() async {
    final response = await http.get(Uri.parse('https://api.betterttv.net/3/cached/badges'));
    return decodeJsonInIsolate(
      response.bodyBytes,
      (json) => [for (final badge in json as List<dynamic>) BetterTTVBadge.fromJson(badge as JsonMap)],
    );
  }
}
