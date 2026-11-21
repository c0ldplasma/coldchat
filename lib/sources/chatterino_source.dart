import '../api/chatterino/chatterino.dart';
import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import 'badge_source.dart';
import 'chat_source.dart';

/// The badges Chatterino gives its developers, contributors and supporters, shown on their messages in every channel.
class ChatterinoSource extends ChatSource with BadgeSource {
  final ChatterinoApi api;

  ChatterinoSource(this.api);

  @override
  String get name => 'Chatterino';

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
    final badges = await api.badges();
    return [
      for (final badge in badges)
        if (badge.tooltip case final tooltip? when tooltip.isNotEmpty)
          if ([badge.image1, badge.image2, badge.image3].nonNulls.where((url) => url.isNotEmpty).toList()
              case final mipmap when mipmap.isNotEmpty)
            BadgeUsers(
              badge: CustomBadge(
                // The tooltip names the badge; the images can move to another host.
                id: 'chatterino-$tooltip',
                name: tooltip,
                // Smallest to largest, like the other sources: the chat shows the last one.
                mipmap: mipmap,
                source: this,
              ),
              users: badge.users,
            ),
    ];
  }
}
