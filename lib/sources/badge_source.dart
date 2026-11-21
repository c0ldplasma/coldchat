import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import 'chat_source.dart';

// TODO: Migrate BadgeSource to use a Map instead of a List
mixin BadgeSource on ChatSource {
  Future<List<CustomBadge>> globalBadges() async => throw UnimplementedError();
  Future<List<CustomBadge>> channelBadges(String uid) async => throw UnimplementedError();
  Future<List<CustomBadge>> userBadges(String uid) async => throw UnimplementedError();
  Future<List<BadgeUsers>> globalUserBadges() async => throw UnimplementedError();
}
