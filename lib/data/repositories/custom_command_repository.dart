import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../custom_command.dart';
import 'box_changes.dart';

/// Settings → Custom commands: the `CustomCommands` box, a list in the order they were added.
class CustomCommandRepository {
  static const String boxName = 'CustomCommands';

  final Box<dynamic> _box;

  /// Takes the open `CustomCommands` box; [open] opens it.
  CustomCommandRepository(this._box);

  static Future<CustomCommandRepository> open() async => CustomCommandRepository(await Hive.openBox<dynamic>(boxName));

  List<CustomCommand> get commands => _box.values.whereType<CustomCommand>().toList();

  late final Listenable changes = BoxChanges(_box);

  Future<void> add(CustomCommand command) => _box.add(command);

  /// Saves changes made to a stored [command].
  Future<void> save(CustomCommand command) => command.save();

  Future<void> delete(CustomCommand command) => command.delete();

  /// The first command whose trigger is [word], ignoring case, or null.
  CustomCommand? commandFor(String word) =>
      commands.firstWhereOrNull((command) => word.toLowerCase() == command.trigger.toLowerCase());

  /// The commands whose trigger starts with [text], ignoring case, for autocompletion.
  Iterable<CustomCommand> commandsStartingWith(String text) =>
      commands.where((command) => command.trigger.toLowerCase().startsWith(text.toLowerCase()));
}
