import 'package:hive_ce/hive_ce.dart';

/// A whisper conversation as it is stored on the device.
class StoredWhisperConversation {
  /// The partner's login and display name.
  final String login;
  final String name;

  /// Whether it is shown as a tab. Closed ones keep their messages and reopen with the next whisper.
  final bool open;
  final bool unread;

  /// When its tab was opened, in milliseconds since the epoch; the tabs are sorted by it.
  final int? openedAt;

  /// The messages as IRC lines, oldest first.
  final List<String> lines;

  const StoredWhisperConversation({
    required this.login,
    required this.name,
    required this.open,
    required this.unread,
    required this.openedAt,
    required this.lines,
  });

  /// Reads a stored map, or returns null when [value] isn't one.
  static StoredWhisperConversation? fromStored(Object? value) {
    if (value is! Map) return null;
    final login = value['login'];
    final name = value['name'];
    if (login is! String || name is! String) return null;
    final openedAt = value['openedAt'];
    final lines = value['lines'];
    return StoredWhisperConversation(
      login: login,
      name: name,
      open: value['open'] == true,
      unread: value['unread'] == true,
      openedAt: openedAt is int ? openedAt : null,
      lines: lines is List ? lines.whereType<String>().toList() : const [],
    );
  }

  Map<String, Object?> toStored() => {
    'login': login,
    'name': name,
    'open': open,
    'unread': unread,
    'openedAt': openedAt,
    'lines': lines,
  };
}

/// Whisper conversations (box `Whispers`). Twitch keeps no whisper history an app can read, so this is the only copy.
/// Each conversation is stored under `<account id>/<partner id>`.
class WhisperRepository {
  static const String boxName = 'Whispers';

  final Box<dynamic> _box;

  /// Takes the open `Whispers` box; [open] opens it.
  WhisperRepository(this._box);

  static Future<WhisperRepository> open() async => WhisperRepository(await Hive.openBox<dynamic>(boxName));

  static String key(String accountId, String partnerId) => '$accountId/$partnerId';

  StoredWhisperConversation? conversation(String accountId, String partnerId) =>
      StoredWhisperConversation.fromStored(_box.get(key(accountId, partnerId)));

  /// [accountId]'s conversations by partner id, in storage order.
  Map<String, StoredWhisperConversation> conversationsOf(String accountId) {
    final prefix = '$accountId/';
    final conversations = <String, StoredWhisperConversation>{};
    for (final key in _box.keys.whereType<String>().where((key) => key.startsWith(prefix))) {
      final conversation = StoredWhisperConversation.fromStored(_box.get(key));
      if (conversation != null) conversations[key.substring(prefix.length)] = conversation;
    }
    return conversations;
  }

  Future<void> save(String accountId, String partnerId, StoredWhisperConversation conversation) =>
      _box.put(key(accountId, partnerId), conversation.toStored());

  Future<void> delete(String accountId, String partnerId) => _box.delete(key(accountId, partnerId));
}
