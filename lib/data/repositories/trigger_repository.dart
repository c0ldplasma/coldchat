import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../message_trigger.dart';
import '../trigger_input.dart';
import '../user_trigger.dart';
import 'box_changes.dart';

/// Settings → Message triggers and User triggers, which highlight or block chat messages: the `MessageTriggers` and
/// `UserTriggers` boxes, each a list in the order they were added.
class TriggerRepository {
  static const String messageTriggersBoxName = 'MessageTriggers';
  static const String userTriggersBoxName = 'UserTriggers';

  final Box<dynamic> _messageTriggers;
  final Box<dynamic> _userTriggers;

  /// Takes the open `MessageTriggers` and `UserTriggers` boxes; [open] opens them.
  TriggerRepository(this._messageTriggers, this._userTriggers);

  static Future<TriggerRepository> open() async {
    final boxes = await Future.wait([
      Hive.openBox<dynamic>(messageTriggersBoxName),
      Hive.openBox<dynamic>(userTriggersBoxName),
    ]);
    return TriggerRepository(boxes[0], boxes[1]);
  }

  List<MessageTrigger> get messageTriggers => _messageTriggers.values.whereType<MessageTrigger>().toList();

  late final Listenable messageTriggerChanges = BoxChanges(_messageTriggers);

  Future<void> addMessageTrigger(MessageTrigger trigger) => _messageTriggers.add(trigger);

  /// Saves changes made to a stored [trigger].
  Future<void> saveMessageTrigger(MessageTrigger trigger) => trigger.save();

  /// Saves the message triggers entered in the trigger sheet in one go (see [parseMessageTriggerInput]): the trigger
  /// being edited, [existing], takes the first entry and the others are added after it. Without [existing], all are
  /// added.
  Future<void> saveMessageTriggerEntries(
    List<MessageTriggerEntry> entries, {
    required MessageTriggerType type,
    MessageTrigger? existing,
  }) async {
    var remaining = entries;
    if (existing != null && entries.isNotEmpty) {
      final first = entries.first;
      existing
        ..type = type.index
        ..pattern = first.pattern
        ..enableRegex = first.enableRegex
        ..caseSensitive = first.caseSensitive;
      await saveMessageTrigger(existing);
      remaining = entries.skip(1).toList();
    }
    await _messageTriggers.addAll([
      for (final entry in remaining)
        MessageTrigger(
          type: type.index,
          pattern: entry.pattern,
          enableRegex: entry.enableRegex,
          caseSensitive: entry.caseSensitive,
        ),
    ]);
  }

  Future<void> deleteMessageTrigger(MessageTrigger trigger) => trigger.delete();

  List<UserTrigger> get userTriggers => _userTriggers.values.whereType<UserTrigger>().toList();

  late final Listenable userTriggerChanges = BoxChanges(_userTriggers);

  Future<void> addUserTrigger(UserTrigger trigger) => _userTriggers.add(trigger);

  /// Saves changes made to a stored [trigger].
  Future<void> saveUserTrigger(UserTrigger trigger) => trigger.save();

  /// Saves the logins entered in the user trigger sheet in one go (see [parseUserTriggerInput]): the trigger being
  /// edited, [existing], takes the first login and the others are added after it. Without [existing], all are added.
  Future<void> saveUserTriggerLogins(
    List<String> logins, {
    required UserTriggerType type,
    UserTrigger? existing,
  }) async {
    var remaining = logins;
    if (existing != null && logins.isNotEmpty) {
      existing
        ..type = type.index
        ..login = logins.first;
      await saveUserTrigger(existing);
      remaining = logins.skip(1).toList();
    }
    await _userTriggers.addAll([for (final login in remaining) UserTrigger(type: type.index, login: login)]);
  }

  Future<void> deleteUserTrigger(UserTrigger trigger) => trigger.delete();

  /// The first user trigger for [login], ignoring case, or null.
  UserTrigger? userTriggerFor(String? login) =>
      userTriggers.firstWhereOrNull((trigger) => trigger.login.toLowerCase() == login?.toLowerCase());
}
