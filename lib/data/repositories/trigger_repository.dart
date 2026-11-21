import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../message_trigger.dart';
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

  Future<void> deleteMessageTrigger(MessageTrigger trigger) => trigger.delete();

  List<UserTrigger> get userTriggers => _userTriggers.values.whereType<UserTrigger>().toList();

  late final Listenable userTriggerChanges = BoxChanges(_userTriggers);

  Future<void> addUserTrigger(UserTrigger trigger) => _userTriggers.add(trigger);

  /// Saves changes made to a stored [trigger].
  Future<void> saveUserTrigger(UserTrigger trigger) => trigger.save();

  Future<void> deleteUserTrigger(UserTrigger trigger) => trigger.delete();

  /// The first user trigger for [login], ignoring case, or null.
  UserTrigger? userTriggerFor(String? login) =>
      userTriggers.firstWhereOrNull((trigger) => trigger.login.toLowerCase() == login?.toLowerCase());
}
