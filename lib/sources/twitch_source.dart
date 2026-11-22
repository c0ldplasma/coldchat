import 'dart:developer';

import '../api/ivr/ivr.dart';
import '../api/twitch/helix_api.dart';
import '../api/twitch/twitch_badge.dart';
import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import '../data/emote.dart';
import 'badge_source.dart';
import 'chat_source.dart';
import 'emote_source.dart';

class TwitchSource extends ChatSource with EmoteSource, BadgeSource {
  /// Helix as the account whose token badges are loaded with: the official route, used whenever there is a login.
  final HelixApi? helix;

  /// Where badges come from when Helix can't be used: without a login, or when the Helix request fails (e.g. an
  /// expired login or a Twitch outage). Without it, no badges load then.
  final IvrApi? ivr;

  TwitchSource({this.helix, this.ivr});

  @override
  String get name => 'Twitch';

  @override
  String? get description => null;

  @override
  Future<List<CustomBadge>> globalBadges() async =>
      _toBadges(await _badgeSets((helix) => helix.globalBadges(), (ivr) => ivr.globalBadges()));

  @override
  Future<List<CustomBadge>> channelBadges(String uid) async =>
      _toBadges(await _badgeSets((helix) => helix.channelBadges(uid), (ivr) => ivr.channelBadges(uid)));

  /// The badge sets from Helix when there is a login, otherwise, or when that fails, from ivr.fi.
  Future<Map<String, Map<String, TwitchBadge>>> _badgeSets(
    Future<Map<String, Map<String, TwitchBadge>>> Function(HelixApi helix) fromHelix,
    Future<Map<String, Map<String, TwitchBadge>>> Function(IvrApi ivr) fromIvr,
  ) async {
    final helix = this.helix;
    final ivr = this.ivr;
    if (helix != null && helix.hasToken) {
      try {
        return await fromHelix(helix);
      } catch (e) {
        if (ivr == null) rethrow;
        log('Couldn\'t load Twitch badges from Helix, trying ivr.fi: $e');
      }
    }
    if (ivr == null) throw Exception('No Twitch login to load badges with');
    return fromIvr(ivr);
  }

  List<CustomBadge> _toBadges(Map<String, Map<String, TwitchBadge>> badgeSets) => [
    for (final badgeSet in badgeSets.entries)
      for (final version in badgeSet.value.entries)
        CustomBadge(
          id: '${badgeSet.key}/${version.key}',
          name: version.value.title,
          description: version.value.description,
          mipmap: [version.value.imageUrl1x, version.value.imageUrl2x, version.value.imageUrl4x],
          source: this,
        ),
  ];

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
