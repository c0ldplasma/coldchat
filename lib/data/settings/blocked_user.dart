import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'blocked_user.g.dart';

@HiveType(typeId: 9)
class BlockedUser extends HiveObject {
  @HiveField(0)
  String? login;

  @HiveField(1)
  String? id;

  BlockedUser({
    this.login,
    this.id,
  });
}
