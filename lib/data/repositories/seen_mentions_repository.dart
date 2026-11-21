import 'dart:async';

import 'package:hive_ce/hive_ce.dart';

/// The mentions already shown as a notification (box `SeenMentions`: message id → time seen in milliseconds since the
/// epoch), so a mention that comes back with the chat history on the next launch isn't notified again.
class SeenMentionsRepository {
  static const String boxName = 'SeenMentions';

  /// How many mentions are remembered. The ones seen longest ago are forgotten first.
  static const int maxEntries = 500;

  final Box<dynamic> _box;

  /// Takes the open `SeenMentions` box; [open] opens it.
  SeenMentionsRepository(this._box);

  static Future<SeenMentionsRepository> open() async => SeenMentionsRepository(await Hive.openBox<dynamic>(boxName));

  bool contains(String messageId) => _box.containsKey(messageId);

  /// Remembers [messageId] as seen [now], forgetting the oldest entries beyond [maxEntries].
  void markSeen(String messageId, {DateTime? now}) {
    if (messageId.isEmpty || _box.containsKey(messageId)) return;
    unawaited(_box.put(messageId, (now ?? DateTime.now()).millisecondsSinceEpoch));
    if (_box.length > maxEntries) {
      // Trim oldest entries (lowest stored timestamps) so the box doesn't
      // grow unbounded across sessions.
      final entries = _box.toMap().entries.toList()..sort((a, b) => _time(a.value).compareTo(_time(b.value)));
      final toRemove = entries.take(_box.length - maxEntries).map((e) => e.key).toList();
      unawaited(_box.deleteAll(toRemove));
    }
  }

  static int _time(Object? value) => value is int ? value : 0;
}
