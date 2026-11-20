import 'dart:convert';

import '../api/dankchat/dankchat.dart';
import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import 'badge_provider.dart';
import 'provider.dart';

class DankChatProvider extends Provider with BadgeProvider {
  @override
  String get name => 'DankChat';

  @override
  String? get description => null;

  @override
  Future<List<CustomBadge>> globalBadges() async => [];

  @override
  Future<List<CustomBadge>> channelBadges(String uid) async => [];

  @override
  Future<List<CustomBadge>> userBadges(String uid) async => [];

  @override
  Future<List<BadgeUsers>> globalUserBadges() async {
    final badges = await DankChat.badges();
    return [
      for (final badge in badges)
        BadgeUsers(
          badge: CustomBadge(
            id: base64Encode(badge.url.codeUnits),
            name: badge.type,
            mipmap: [
              badge.url,
            ],
            provider: this,
          ),
          users: badge.users,
        ),
    ];
  }
}
