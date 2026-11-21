import 'package:hive_ce/hive_ce.dart';

part 'custom_command.g.dart';

@HiveType(typeId: 12)
class CustomCommand extends HiveObject {
  @HiveField(0)
  String trigger;

  @HiveField(1)
  String command;

  CustomCommand({
    required this.trigger,
    required this.command,
  });

  /// The message to send when [input], composer text starting with [trigger], is sent.
  ///
  /// [input] is trimmed and split at single spaces into words; word 0 is the trigger. In [command], `{N}` becomes
  /// word N and `{N+}` words N to the end joined by spaces. A placeholder without a number, with 0 or past the
  /// last word becomes empty. All `{N}` are replaced before any `{N+}`, so a word that itself reads `{N+}` is
  /// expanded as well.
  String expand(String input) {
    final words = input.trim().split(' ');
    bool inRange(int? index) => index != null && index < words.length && index > 0;

    return command
        .replaceAllMapped(RegExp(r'{\d*}'), (match) {
          final matchText = match.group(0)!;
          final index = int.tryParse(matchText.substring(1, matchText.length - 1));
          return inRange(index) ? words[index!] : '';
        })
        .replaceAllMapped(RegExp(r'{\d*\+}'), (match) {
          final matchText = match.group(0)!;
          final index = int.tryParse(matchText.substring(1, matchText.length - 2));
          return inRange(index) ? words.skip(index!).join(' ') : '';
        });
  }
}
