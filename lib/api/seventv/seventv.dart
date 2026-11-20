import 'package:http/http.dart' as http;

import '../json_isolate.dart';
import 'seventv_cosmetics.dart';
import 'seventv_emote.dart';

class SevenTV {
  static Future<List<SevenTVEmote>> globalEmotes() async {
    final response = await http.get(Uri.parse('https://7tv.io/v3/emote-sets/global'));
    return decodeJsonInIsolate(
      response.bodyBytes,
      (json) => [
        for (final emote in (json as JsonMap)['emotes'] as List<dynamic>) SevenTVEmote.fromJson(emote as JsonMap),
      ],
    );
  }

  static Future<List<SevenTVEmote>> channelEmotes(String uid) async {
    final response = await http.get(Uri.parse('https://7tv.io/v3/users/twitch/$uid'));
    return decodeJsonInIsolate(response.bodyBytes, (json) {
      final data = json as JsonMap;
      if (data['status_code'] == 404) return <SevenTVEmote>[];
      final emotes = (data['emote_set'] as JsonMap?)?['emotes'] as List<dynamic>? ?? <dynamic>[];
      return [for (final emote in emotes) SevenTVEmote.fromJson(emote as JsonMap)];
    });
  }

  static Future<SevenTVCosmetics> cosmetics() async {
    final response = await http.get(Uri.parse('https://7tv.io/v2/cosmetics?user_identifier=twitch_id'));
    return decodeJsonInIsolate(response.bodyBytes, (json) => SevenTVCosmetics.fromJson(json as JsonMap));
  }
}
