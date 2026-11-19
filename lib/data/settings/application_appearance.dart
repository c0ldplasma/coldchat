import 'package:hive/hive.dart';

part 'application_appearance.g.dart';

@HiveType(typeId: 7)
class ApplicationAppearance extends HiveObject {
  @HiveField(0)
  bool compact = false;

  @HiveField(1)
  String themeMode = 'dark';

  @HiveField(2)
  bool highContrast = false;

  /// Dark mode with a pure black chat, for OLED screens.
  @HiveField(3, defaultValue: false)
  bool oledBlack = false;
}
