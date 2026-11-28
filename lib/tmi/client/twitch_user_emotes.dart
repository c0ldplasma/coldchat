import 'dart:developer';

import '../../api/twitch/helix_api.dart';
import '../../api/twitch/twitch_badge.dart';
import '../../api/twitch/twitch_emote.dart';
import '../../data/emote.dart';
import '../../sources/chat_source.dart';

/// The `emote_type`s of emotes that belong to a channel: its subscriber, follower and Bits tier emotes. These get a
/// section of their own in the emote picker; every other Twitch emote (globals, Prime, Turbo, rewards, …) stays in the
/// Twitch section.
const channelEmoteTypes = {'subscriptions', 'follower', 'bitstier'};

/// How many channels' badges are asked for at once.
const _badgeRequestsAtOnce = 10;

/// The channel that [emote] belongs to, or null for an emote that isn't a channel's.
String? channelOwnerOf(TwitchEmote emote) {
  if (!channelEmoteTypes.contains(emote.emoteType)) return null;
  final owner = emote.ownerId;
  // Twitch's own emotes have the owner "0" or "twitch".
  if (owner.isEmpty || owner == '0' || owner == 'twitch') return null;
  return owner;
}

/// The image of a channel's base subscriber badge in [badgeSets] (its badge sets from Helix), or null without one.
/// That's the version for new subscribers, "0" (or "1" on older channels), else the lowest month count among the
/// tier 1 versions (tier 2 and 3 have versions from 2000 and 3000 on).
String? subscriberBadgeUrl(Map<String, Map<String, TwitchBadge>> badgeSets) {
  final versions = badgeSets['subscriber'];
  if (versions == null || versions.isEmpty) return null;
  TwitchBadge? lowest;
  int? lowestMonths;
  for (final MapEntry(key: id, value: badge) in versions.entries) {
    final months = int.tryParse(id);
    if (months == null || months >= 1000) continue;
    if (lowestMonths == null || months < lowestMonths) {
      lowest = badge;
      lowestMonths = months;
    }
  }
  return (lowest ?? versions.values.first).imageUrl4x;
}

/// The account's Twitch emotes for the picker. Emotes of a channel ([channelOwnerOf]) are put in a section named after
/// the channel ([ownerNames], by user id), with its subscriber badge ([ownerBadges]) as the section's icon. The other
/// emotes come first, in Twitch's order, then the channels by name. A channel whose name is unknown (the lookup
/// failed) stays in the Twitch section.
List<Emote> twitchUserEmotesFrom(
  List<TwitchEmote> emotes,
  ChatSource twitch, {
  Map<String, String> ownerNames = const {},
  Map<String, String> ownerBadges = const {},
}) {
  final others = <Emote>[];
  final byChannel = <String, List<Emote>>{};
  for (final emote in emotes) {
    final owner = channelOwnerOf(emote);
    final name = owner == null ? null : ownerNames[owner];
    final converted = Emote(
      id: emote.id,
      mipmap: emote.images.values.toList(),
      name: emote.name,
      source: twitch,
      category: name,
      categoryIcon: name == null ? null : ownerBadges[owner],
    );
    if (name == null) {
      others.add(converted);
    } else {
      byChannel.putIfAbsent(owner!, () => []).add(converted);
    }
  }
  final channels = byChannel.keys.toList()
    ..sort((a, b) => ownerNames[a]!.toLowerCase().compareTo(ownerNames[b]!.toLowerCase()));
  return [
    ...others,
    for (final channel in channels) ...byChannel[channel]!,
  ];
}

/// Loads the emotes of [emoteSetIds] with [helix], and the names and subscriber badges of the channels they belong
/// to, see [twitchUserEmotesFrom]. When the names or a channel's badges can't be loaded, those emotes go without them.
Future<List<Emote>> loadTwitchUserEmotes(HelixApi helix, List<String> emoteSetIds, ChatSource twitch) async {
  final emotes = await helix.emoteSets(emoteSetIds);
  final owners = {for (final emote in emotes) ?channelOwnerOf(emote)}.toList();
  if (owners.isEmpty) return twitchUserEmotesFrom(emotes, twitch);

  Future<Map<String, String>> names() async {
    try {
      return {for (final user in await helix.usersById(owners)) user.id: user.displayName};
    } catch (e) {
      log('Couldn\'t get the channels of twitch user emotes: $e');
      return const {};
    }
  }

  Future<Map<String, String>> badges() async {
    final badges = <String, String>{};
    for (var i = 0; i < owners.length; i += _badgeRequestsAtOnce) {
      await Future.wait(
        owners.skip(i).take(_badgeRequestsAtOnce).map((owner) async {
          try {
            final url = subscriberBadgeUrl(await helix.channelBadges(owner));
            if (url != null) badges[owner] = url;
          } catch (e) {
            log('Couldn\'t get the badges of channel $owner: $e');
          }
        }),
      );
    }
    return badges;
  }

  final (ownerNames, ownerBadges) = await (names(), badges()).wait;
  return twitchUserEmotesFrom(emotes, twitch, ownerNames: ownerNames, ownerBadges: ownerBadges);
}
