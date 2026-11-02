import '../data/custom_badge.dart';
import '../data/badge_users.dart';
import '/api/frankerfacez/frankerfacez.dart';
import '/api/frankerfacez/frankerfacez_emote.dart';
import '/data/emote.dart';
import 'badge_provider.dart';
import 'emote_provider.dart';
import 'provider.dart';

class FrankerFaceZProvider extends Provider with EmoteProvider, BadgeProvider {
  @override
  String get name => 'FrankerFaceZ';

  @override
  String? get description => null;

  @override
  Future<List<Emote>> globalEmotes() async {
    final globalSets = await FrankerFaceZ.globalSets();
    return [
      for (final emoteSet in globalSets)
        for (final emote in emoteSet.emoticons)
          Emote(
            id: '${emote.id}',
            name: emote.name,
            mipmap: [
              for (final url in emote.urls.values) url,
            ],
            provider: this,
            flags: _flags(emote),
          ),
    ];
  }

  @override
  Future<List<Emote>> channelEmotes(String uid) async {
    final user = await FrankerFaceZ.user(uid);
    return [
      for (final emoteSet in user.sets.values)
        for (final emote in emoteSet.emoticons)
          Emote(
            id: '${emote.id}',
            name: emote.name,
            mipmap: [
              for (final url in emote.urls.values) url,
            ],
            provider: this,
            flags: _flags(emote),
          ),
    ];
  }

  // FrankerFaceZ modifier_flags. Modifiers with Hidden set are effects on the emote before them (ffzX, ffzW, …);
  // the others are overlay images. Only the effects that need no animation are supported.
  static const int _hidden = 1 << 0;
  static const Map<int, int> _effects = {
    1 << 1: EmoteFlags.flipX,
    1 << 2: EmoteFlags.flipY,
    1 << 3: EmoteFlags.growX,
    1 << 8: EmoteFlags.rotate90,
    1 << 9: EmoteFlags.greyscale,
    1 << 10: EmoteFlags.sepia,
  };

  static int _flags(FrankerFaceZEmote emote) {
    if (!emote.modifier) return 0;
    final modifierFlags = emote.modifierFlags ?? 0;
    if (modifierFlags & _hidden == 0) return EmoteFlags.overlay;
    var flags = EmoteFlags.modifier;
    _effects.forEach((ffz, flag) {
      if (modifierFlags & ffz != 0) flags |= flag;
    });
    return flags;
  }

  @override
  Future<List<CustomBadge>> globalBadges() async => [];

  @override
  Future<List<CustomBadge>> channelBadges(String uid) async => [];

  @override
  Future<List<CustomBadge>> userBadges(String uid) async => [];

  @override
  Future<List<BadgeUsers>> globalUserBadges() async {
    final badges = await FrankerFaceZ.badges();
    return [
      for (final badge in badges.badges)
        BadgeUsers(
          badge: CustomBadge(
            id: '${badge.id}',
            name: badge.title,
            mipmap: [
              for (final url in badge.urls.values) url,
            ],
            provider: this,
          ),
          users: badges.users['${badge.id}']?.map((e) => '$e').toList() ?? [],
        ),
    ];
  }

  @override
  String? emoteUrl(String id) => 'https://www.frankerfacez.com/emoticon/$id';
}
