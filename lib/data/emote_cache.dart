import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// The disk cache for emote and badge images, kept apart from the default cache that avatars, thumbnails and embeds
/// use. Instead of the default 200 files it keeps up to [maxBytes] and evicts the least recently used images first:
/// one animated emote can be a hundred times the size of a static one, so a file count says little about disk use.
///
/// Validity still follows each server's `Cache-Control: max-age`. BTTV and 7TV send 180 days and a year; Twitch and
/// FFZ send a day, but can change an image under the same URL, and answer the daily check with an empty `304`.
class EmoteCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'emoteImages';

  /// About 2500 mostly animated emotes (WebP 7TV emotes average about 200 KB), many more when they're static.
  static const maxBytes = 500 * 1000 * 1000;

  /// Images not shown for this long are removed even under the budget.
  static const stalePeriod = Duration(days: 90);

  static final EmoteCacheManager instance = EmoteCacheManager._(
    ByteBudgetCacheObjectProvider(databaseName: key, maxBytes: maxBytes),
  );

  final ByteBudgetCacheObjectProvider _repo;

  EmoteCacheManager._(this._repo) : super(Config(key, stalePeriod: stalePeriod, repo: _repo));

  /// The bytes the cached images take on disk.
  Future<int> totalBytes() => _repo.totalBytes();
}

/// A [CacheObjectProvider] that limits the cache by total bytes instead of by number of files.
class ByteBudgetCacheObjectProvider extends CacheObjectProvider {
  static const _table = 'cacheObject';

  final int maxBytes;
  Future<bool>? _opened;

  ByteBudgetCacheObjectProvider({required super.databaseName, required this.maxBytes});

  Future<int> totalBytes() async {
    // The cache manager opens the database too; this only waits for it when asked before that finished.
    await (_opened ??= open());
    return _sumLength();
  }

  Future<int> _sumLength() async {
    final rows = await db!.rawQuery('SELECT SUM(${CacheObject.columnLength}) AS total FROM $_table');
    return (rows.first['total'] as int?) ?? 0;
  }

  /// Ignores the file count [capacity] the cache manager passes and returns what is over [maxBytes] instead.
  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async {
    if (await _sumLength() <= maxBytes) return [];
    final rows = await db!.query(_table, orderBy: '${CacheObject.columnTouched} DESC');
    return overBudget(CacheObject.fromMapList(rows), maxBytes);
  }
}

/// The objects of [newestFirst] (most recently used first) that don't fit into [maxBytes] after the ones before
/// them: the least recently used, which eviction removes. An object of unknown length counts as 0 bytes.
List<CacheObject> overBudget(List<CacheObject> newestFirst, int maxBytes) {
  var total = 0;
  return [
    for (final object in newestFirst)
      if ((total += object.length ?? 0) > maxBytes) object,
  ];
}
