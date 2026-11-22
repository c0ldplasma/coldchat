import '../api_client.dart';
import '../twitch/twitch_badge.dart';

/// ivr.fi, a community API that serves Twitch's chat badges without a login, in Helix's format. Only used while
/// Helix can't be (no login, or the Helix request failed), so the opened channels aren't sent to a third party
/// otherwise.
class IvrApi {
  final ApiClient _api;

  IvrApi(this._api);

  static const String _base = 'https://api.ivr.fi/v2/twitch/badges';

  Future<Map<String, Map<String, TwitchBadge>>> globalBadges() =>
      _api.getJson(Uri.parse('$_base/global'), _badgeSetsFromJson, inIsolate: true);

  /// The badges of the channel with the user id [uid], e.g. its subscriber badges.
  Future<Map<String, Map<String, TwitchBadge>>> channelBadges(String uid) => _api.getJson(
    Uri.parse('$_base/channel').replace(queryParameters: {'id': uid}),
    _badgeSetsFromJson,
    inIsolate: true,
  );

  // Static, so it can be sent to the isolate that decodes the response. The same badge sets as Helix's, but as a bare
  // list instead of under "data".
  static Map<String, Map<String, TwitchBadge>> _badgeSetsFromJson(dynamic json) =>
      twitchBadgeSetsFromJson(json as List<dynamic>);
}
