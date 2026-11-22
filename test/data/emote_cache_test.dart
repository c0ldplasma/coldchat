import 'package:coldchat/data/emote_cache.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

CacheObject _object(int id, int? length) => CacheObject(
  'https://cdn.7tv.app/emote/$id/4x.webp',
  relativePath: '$id.file',
  validTill: DateTime(2027),
  id: id,
  length: length,
);

void main() {
  group('overBudget', () {
    test('keeps the most recently used objects that fit and returns the rest', () {
      final newestFirst = [_object(1, 40), _object(2, 40), _object(3, 40), _object(4, 10)];

      expect(overBudget(newestFirst, 100).map((o) => o.id), [3, 4]);
    });

    test('an object that exactly fills the budget stays', () {
      expect(overBudget([_object(1, 60), _object(2, 40)], 100), isEmpty);
    });

    test('returns nothing when everything fits, or when the cache is empty', () {
      expect(overBudget([_object(1, 10), _object(2, 20)], 100), isEmpty);
      expect(overBudget([], 100), isEmpty);
    });

    test('an object of unknown length counts as 0 bytes', () {
      expect(overBudget([_object(1, 100), _object(2, null), _object(3, 1)], 100).map((o) => o.id), [3]);
    });
  });

  test('the emote cache keeps 500 MB for 90 days in its own cache', () {
    expect(EmoteCacheManager.maxBytes, 500 * 1000 * 1000);
    expect(EmoteCacheManager.stalePeriod, const Duration(days: 90));
    expect(EmoteCacheManager.key, isNot(DefaultCacheManager.key));
  });
}
