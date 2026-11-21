import 'dart:async';
import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

/// The `EmoteBadgeCache` box: emotes, badges and chat history as JSON strings, so first paint after launch or after
/// opening a channel doesn't have to wait on HTTP requests. Turning them into emotes and badges is up to
/// `EmoteBadgeCache`; this keeps the keys and evicts the channels opened longest ago.
class EmoteBadgeCacheRepository {
  static const String boxName = 'EmoteBadgeCache';

  // Cap the number of channels whose emotes/badges/history we retain on disk
  // so the box doesn't grow without bound as more channels are opened.
  static const int maxCachedChannels = 60;
  static const String _lruKey = 'channelLru';

  static const String globalEmotesKey = 'globalEmotes';
  static const String globalBadgesKey = 'globalBadges';
  static const String globalUserBadgesKey = 'globalUserBadges';
  static const String bttvProBadgesKey = 'bttvProBadges';
  static String twitchUserEmotesKey(String userId) => 'twitchUserEmotes:$userId';
  static String channelEmotesKey(String channelLogin) => 'channelEmotes:v2:$channelLogin';
  static String channelBadgesKey(String channelLogin) => 'channelBadges:v2:$channelLogin';
  static String historyKey(String channelLogin) => 'history:v2:$channelLogin';

  final Box<dynamic> _box;

  // Channel access order (most-recent last), held in memory so a save doesn't
  // decode the stored list every time. Loaded once on construction.
  late final List<String> _lru;

  /// Takes the open `EmoteBadgeCache` box; [open] opens it.
  EmoteBadgeCacheRepository(this._box) {
    _purgeLegacyKeys();
    final lru = readList(_lruKey);
    _lru = lru == null ? [] : List<String>.from(lru);
  }

  static Future<EmoteBadgeCacheRepository> open() async =>
      EmoteBadgeCacheRepository(await Hive.openBox<dynamic>(boxName));

  // Earlier versions keyed channel caches by room id (and an un-versioned
  // login). Drop those orphaned entries — they are never read again.
  void _purgeLegacyKeys() {
    final stale = _box.keys.where((k) {
      if (k is! String) return false;
      final isChannelScoped =
          k.startsWith('channelEmotes:') || k.startsWith('channelBadges:') || k.startsWith('history:');
      return isChannelScoped && !k.contains(':v2:');
    }).toList();
    if (stale.isNotEmpty) unawaited(_box.deleteAll(stale));
  }

  /// Marks [channelLogin]'s entries as the most recently used, and evicts the oldest channels' entries once more than
  /// [maxCachedChannels] are stored. Call it whenever a channel's entry is written.
  void touchChannel(String channelLogin) {
    if (_lru.isNotEmpty && _lru.last == channelLogin) return;
    _lru.remove(channelLogin);
    _lru.add(channelLogin);
    while (_lru.length > maxCachedChannels) {
      final evict = _lru.removeAt(0);
      unawaited(_box.delete(channelEmotesKey(evict)));
      unawaited(_box.delete(channelBadgesKey(evict)));
      unawaited(_box.delete(historyKey(evict)));
    }
    unawaited(_box.put(_lruKey, json.encode(_lru)));
  }

  /// The JSON list stored under [key], or null when there is none or it can't be read.
  List<dynamic>? readList(String key) {
    final raw = _box.get(key);
    if (raw is! String) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return null;
  }

  /// Stores [data] as JSON under [key].
  Future<void> writeJson(String key, Object data) => _box.put(key, json.encode(data));

  /// BetterTTV Pro badge urls by Twitch user id, oldest sighting first.
  Map<String, String> loadBttvProBadges() {
    final raw = _box.get(bttvProBadgesKey);
    if (raw is! String) return {};
    try {
      return Map<String, String>.from(json.decode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveBttvProBadges(Map<String, String> badgeUrls) => writeJson(bttvProBadgesKey, badgeUrls);

  /// The last messages of [channelLogin]'s chat as IRC lines.
  List<String> loadHistory(String channelLogin) {
    final list = readList(historyKey(channelLogin));
    return list == null ? const [] : List<String>.from(list);
  }

  Future<void> saveHistory(String channelLogin, List<String> messages) {
    touchChannel(channelLogin);
    return writeJson(historyKey(channelLogin), messages);
  }
}
