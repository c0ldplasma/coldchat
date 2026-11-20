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
}
