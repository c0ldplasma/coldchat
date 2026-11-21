import '../api_client.dart';
import '../json_isolate.dart';
import 'betterttv_badge.dart';
import 'betterttv_emote.dart';
import 'betterttv_user.dart';

/// BetterTTV's emotes and badges. No login.
class BttvApi {
  final ApiClient _api;

  BttvApi(this._api);

  Future<List<BetterTTVEmote>> globalEmotes() =>
      _api.getJson(Uri.parse('https://api.betterttv.net/3/cached/emotes/global'), _emotes, inIsolate: true);

  /// The BetterTTV account of the Twitch user [uid], or null when there is none.
  Future<BetterTTVUser?> user(String uid) async {
    try {
      return await _api.getJson(
        Uri.parse('https://api.betterttv.net/3/cached/users/twitch/$uid'),
        _user,
        inIsolate: true,
      );
    } on ApiException catch (e) {
      // BetterTTV answers 404 for a Twitch user without a BetterTTV account.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<BetterTTVBadge>> badges() =>
      _api.getJson(Uri.parse('https://api.betterttv.net/3/cached/badges'), _badges, inIsolate: true);

  // Static, so they can be sent to the isolate that decodes the response.
  static List<BetterTTVEmote> _emotes(dynamic json) => [
    for (final emote in json as List<dynamic>) BetterTTVEmote.fromJson(emote as JsonMap),
  ];

  static BetterTTVUser? _user(dynamic json) {
    final data = json as JsonMap;
    return data['id'] == null ? null : BetterTTVUser.fromJson(data);
  }

  static List<BetterTTVBadge> _badges(dynamic json) => [
    for (final badge in json as List<dynamic>) BetterTTVBadge.fromJson(badge as JsonMap),
  ];
}
