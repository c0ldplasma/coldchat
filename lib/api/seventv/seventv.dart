import '../api_client.dart';
import '../json_isolate.dart';
import 'seventv_cosmetics.dart';
import 'seventv_emote.dart';

/// 7TV's emotes and badges (cosmetics). No login.
class SevenTvApi {
  final ApiClient _api;

  SevenTvApi(this._api);

  Future<List<SevenTVEmote>> globalEmotes() =>
      _api.getJson(Uri.parse('https://7tv.io/v3/emote-sets/global'), _globalEmotes, inIsolate: true);

  /// The emotes of the Twitch user [uid]; none when the user has no 7TV account.
  Future<List<SevenTVEmote>> channelEmotes(String uid) async {
    try {
      return await _api.getJson(Uri.parse('https://7tv.io/v3/users/twitch/$uid'), _channelEmotes, inIsolate: true);
    } on ApiException catch (e) {
      // 7TV answers 404 for a Twitch user without a 7TV account.
      if (e.statusCode == 404) return <SevenTVEmote>[];
      rethrow;
    }
  }

  Future<SevenTVCosmetics> cosmetics() =>
      _api.getJson(Uri.parse('https://7tv.io/v2/cosmetics?user_identifier=twitch_id'), _cosmetics, inIsolate: true);

  // Static, so they can be sent to the isolate that decodes the response.
  static List<SevenTVEmote> _globalEmotes(dynamic json) => [
    for (final emote in (json as JsonMap)['emotes'] as List<dynamic>) SevenTVEmote.fromJson(emote as JsonMap),
  ];

  static List<SevenTVEmote> _channelEmotes(dynamic json) {
    final data = json as JsonMap;
    if (data['status_code'] == 404) return <SevenTVEmote>[];
    final emotes = (data['emote_set'] as JsonMap?)?['emotes'] as List<dynamic>? ?? <dynamic>[];
    return [for (final emote in emotes) SevenTVEmote.fromJson(emote as JsonMap)];
  }

  static SevenTVCosmetics _cosmetics(dynamic json) => SevenTVCosmetics.fromJson(json as JsonMap);
}
