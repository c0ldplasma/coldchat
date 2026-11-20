import 'package:hive_ce/hive_ce.dart';

part 'chat_settings.g.dart';

@HiveType(typeId: 15)
class ChatSettings extends HiveObject {
  @HiveField(0)
  bool userAutocompletionWithAt = false;

  @HiveField(1)
  bool emoteAutocompletionWithColon = false;

  /// Whether image links in chat are shown as images right away. Off by default: the images live on arbitrary
  /// websites that neither Twitch nor anyone else moderates, so each one is only shown when the user asks.
  @HiveField(2, defaultValue: false)
  bool showLinkImages = false;
}
