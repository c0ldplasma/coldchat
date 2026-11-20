import 'package:hive_ce/hive_ce.dart';

part 'user_data.g.dart';

@HiveType(typeId: 3)
class UserData extends HiveObject {
  @HiveField(0)
  String displayName;

  @HiveField(1)
  String avatarUrl;

  @HiveField(2)
  String offlineUrl;

  UserData({
    required this.displayName,
    required this.avatarUrl,
    required this.offlineUrl,
  });
}
