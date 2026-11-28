import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import '../data/emote.dart';
import '../data/repositories/emote_badge_cache_repository.dart';
import '../sources/chat_source.dart';
import '../sources/emote_source.dart';

/// Turns the emotes and badges kept in [EmoteBadgeCacheRepository] back into objects, so first paint after launch
/// or after opening a channel doesn't have to wait on source HTTP requests.
class EmoteBadgeCache {
  final EmoteBadgeCacheRepository repository;
  final List<ChatSource> sources;

  EmoteBadgeCache({required this.repository, required this.sources});

  ChatSource? _sourceByName(String? name) {
    if (name == null) return null;
    for (final p in sources) {
      if (p.name == name) return p;
    }
    return null;
  }

  // The cached JSON keeps the key 'provider' (and the source names, e.g. '7TV') from before the rename to "sources",
  // so caches written by earlier versions still load.
  Map<String, dynamic> _emoteToJson(Emote e) => {
    'id': e.id,
    'name': e.name,
    'code': e.code,
    'description': e.description,
    'mipmap': e.mipmap,
    'flags': e.flags,
    'provider': e.source.name,
    'category': e.category,
    'categoryIcon': e.categoryIcon,
    'ownerId': e.ownerId,
  };

  Emote? _emoteFromJson(Map<String, dynamic> m) {
    final source = _sourceByName(m['provider'] as String?);
    // Also drops emotes cached from a source that no longer serves emotes,
    // or no longer exists, instead of showing them until the next refresh
    // overwrites the cache.
    if (source is! EmoteSource) return null;
    return Emote(
      id: m['id'] as String,
      name: m['name'] as String,
      code: m['code'] as String?,
      description: m['description'] as String?,
      mipmap: List<String>.from(m['mipmap'] as List),
      flags: (m['flags'] as int?) ?? 0,
      source: source,
      category: m['category'] as String?,
      categoryIcon: m['categoryIcon'] as String?,
      ownerId: m['ownerId'] as String?,
    );
  }

  Map<String, dynamic> _badgeToJson(CustomBadge b) => {
    'id': b.id,
    'name': b.name,
    'description': b.description,
    'mipmap': b.mipmap,
    'flags': b.flags,
    'provider': b.source.name,
  };

  CustomBadge? _badgeFromJson(Map<String, dynamic> m) {
    final source = _sourceByName(m['provider'] as String?);
    if (source == null) return null;
    return CustomBadge(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      mipmap: List<String>.from(m['mipmap'] as List),
      flags: (m['flags'] as int?) ?? 0,
      source: source,
    );
  }

  List<dynamic>? _decode(String key) => repository.readList(key);

  Future<void> _encode(String key, List<Map<String, dynamic>> data) => repository.writeJson(key, data);

  List<Emote> loadEmotes(String key) {
    final list = _decode(key);
    if (list == null) return const [];
    final emotes = <Emote>[];
    for (final entry in list) {
      if (entry is Map) {
        final e = _emoteFromJson(Map<String, dynamic>.from(entry));
        if (e != null) emotes.add(e);
      }
    }
    return emotes;
  }

  Future<void> saveEmotes(String key, List<Emote> emotes) {
    return _encode(key, emotes.map(_emoteToJson).toList());
  }

  List<CustomBadge> loadBadges(String key) {
    final list = _decode(key);
    if (list == null) return const [];
    final badges = <CustomBadge>[];
    for (final entry in list) {
      if (entry is Map) {
        final b = _badgeFromJson(Map<String, dynamic>.from(entry));
        if (b != null) badges.add(b);
      }
    }
    return badges;
  }

  Future<void> saveBadges(String key, List<CustomBadge> badges) {
    return _encode(key, badges.map(_badgeToJson).toList());
  }

  List<BadgeUsers> loadUserBadges(String key) {
    final list = _decode(key);
    if (list == null) return const [];
    final entries = <BadgeUsers>[];
    for (final entry in list) {
      if (entry is Map) {
        final badgeMap = entry['badge'];
        if (badgeMap is! Map) continue;
        final badge = _badgeFromJson(Map<String, dynamic>.from(badgeMap));
        if (badge == null) continue;
        entries.add(
          BadgeUsers(
            badge: badge,
            users: List<String>.from(entry['users'] as List? ?? const []),
          ),
        );
      }
    }
    return entries;
  }

  Future<void> saveUserBadges(String key, List<BadgeUsers> entries) {
    return _encode(
      key,
      entries
          .map(
            (entry) => {
              'badge': _badgeToJson(entry.badge),
              'users': entry.users,
            },
          )
          .toList(),
    );
  }

  static const String globalEmotesKey = EmoteBadgeCacheRepository.globalEmotesKey;
  static const String globalBadgesKey = EmoteBadgeCacheRepository.globalBadgesKey;
  static const String globalUserBadgesKey = EmoteBadgeCacheRepository.globalUserBadgesKey;
  static String twitchUserEmotesKey(String userId) => EmoteBadgeCacheRepository.twitchUserEmotesKey(userId);

  /// BetterTTV Pro badge urls by Twitch user id, oldest sighting first.
  Map<String, String> loadBttvProBadges() => repository.loadBttvProBadges();

  Future<void> saveBttvProBadges(Map<String, String> badgeUrls) => repository.saveBttvProBadges(badgeUrls);

  // Channel-scoped helpers that also maintain the LRU eviction index.
  List<Emote> loadChannelEmotes(String channelLogin) =>
      loadEmotes(EmoteBadgeCacheRepository.channelEmotesKey(channelLogin));

  Future<void> saveChannelEmotes(String channelLogin, List<Emote> emotes) {
    repository.touchChannel(channelLogin);
    return saveEmotes(EmoteBadgeCacheRepository.channelEmotesKey(channelLogin), emotes);
  }

  List<CustomBadge> loadChannelBadges(String channelLogin) =>
      loadBadges(EmoteBadgeCacheRepository.channelBadgesKey(channelLogin));

  Future<void> saveChannelBadges(String channelLogin, List<CustomBadge> badges) {
    repository.touchChannel(channelLogin);
    return saveBadges(EmoteBadgeCacheRepository.channelBadgesKey(channelLogin), badges);
  }

  List<String> loadHistory(String channelLogin) => repository.loadHistory(channelLogin);

  Future<void> saveHistory(String channelLogin, List<String> messages) =>
      repository.saveHistory(channelLogin, messages);
}
