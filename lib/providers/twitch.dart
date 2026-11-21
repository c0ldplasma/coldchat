import '../api/twitch/helix_api.dart';
import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import '../data/emote.dart';
import 'badge_provider.dart';
import 'emote_provider.dart';
import 'provider.dart';

class TwitchProvider extends Provider with EmoteProvider, BadgeProvider {
  /// Helix as the account whose token badges are loaded with. Badges can't be loaded without one, e.g. while
  /// browsing anonymously or without [helix].
  final HelixApi? helix;

  TwitchProvider({this.helix});

  HelixApi get _requireHelix {
    final helix = this.helix;
    if (helix == null || !helix.hasToken) throw Exception('No Twitch login to load badges with');
    return helix;
  }

  @override
  String get name => 'Twitch';

  @override
  String? get description => null;

  @override
  Future<List<CustomBadge>> globalBadges() async {
    final twitchBadges = await _requireHelix.globalBadges();
    return [
      for (final twitchBadgeData in twitchBadges.entries)
        for (final twitchBadgeVersion in twitchBadgeData.value.entries)
          CustomBadge(
            id: '${twitchBadgeData.key}/${twitchBadgeVersion.key}',
            name: twitchBadgeVersion.value.title,
            description: twitchBadgeVersion.value.description,
            mipmap: [
              twitchBadgeVersion.value.imageUrl1x,
              twitchBadgeVersion.value.imageUrl2x,
              twitchBadgeVersion.value.imageUrl4x,
            ],
            provider: this,
          ),
    ];
  }

  @override
  Future<List<CustomBadge>> channelBadges(String uid) async {
    final twitchBadges = await _requireHelix.channelBadges(uid);
    return [
      for (final twitchBadgeData in twitchBadges.entries)
        for (final twitchBadgeVersion in twitchBadgeData.value.entries)
          CustomBadge(
            id: '${twitchBadgeData.key}/${twitchBadgeVersion.key}',
            name: twitchBadgeVersion.value.title,
            description: twitchBadgeVersion.value.description,
            mipmap: [
              twitchBadgeVersion.value.imageUrl1x,
              twitchBadgeVersion.value.imageUrl2x,
              twitchBadgeVersion.value.imageUrl4x,
            ],
            provider: this,
          ),
    ];
  }

  @override
  Future<List<CustomBadge>> userBadges(String uid) async => [];

  @override
  Future<List<BadgeUsers>> globalUserBadges() async => [];

  @override
  Future<List<Emote>> globalEmotes() async => [];

  @override
  Future<List<Emote>> channelEmotes(String uid) async => [];

  @override
  String? emoteUrl(String id) => null;
}
