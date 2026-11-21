import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'message_trigger.g.dart';

enum MessageTriggerType {
  mention,
  block,
}

@HiveType(typeId: 13)
class MessageTrigger extends HiveObject {
  @HiveField(0)
  int type;

  @HiveField(1)
  String pattern;

  @HiveField(2)
  bool enableRegex;

  @HiveField(3)
  bool caseSensitive;

  @HiveField(4)
  bool showInMentions;

  @HiveField(5)
  bool sendNotification;

  @HiveField(6)
  bool playSound;

  MessageTrigger({
    required this.type,
    required this.pattern,
    this.enableRegex = false,
    this.caseSensitive = false,
    this.showInMentions = true,
    this.sendNotification = true,
    this.playSound = true,
  });

  /// Compiled patterns by `caseSensitive` and pattern, so a regex isn't recompiled for every chat message. A pattern
  /// that doesn't compile is stored as null.
  static final Map<(String, bool), RegExp?> _regexCache = {};

  /// [pattern] compiled as a regex, or null when it isn't a valid one.
  static RegExp? compileRegex(String pattern, {required bool caseSensitive}) =>
      _regexCache.putIfAbsent((pattern, caseSensitive), () {
        try {
          return RegExp(pattern, caseSensitive: caseSensitive);
        } on FormatException {
          return null;
        }
      });

  /// Whether [pattern] can be saved as a regex trigger.
  static bool isValidRegex(String pattern) => compileRegex(pattern, caseSensitive: true) != null;

  /// Whether [body] matches this trigger's [pattern] as a regex. An invalid pattern matches nothing and never throws,
  /// so a bad trigger can't break message parsing.
  bool matchesRegex(String body) => compileRegex(pattern, caseSensitive: caseSensitive)?.hasMatch(body) ?? false;
}
