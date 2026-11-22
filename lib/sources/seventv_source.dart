import '../api/seventv/seventv.dart';
import '../api/seventv/seventv_emote.dart';
import '../data/badge_users.dart';
import '../data/custom_badge.dart';
import '../data/emote.dart';
import 'badge_source.dart';
import 'chat_source.dart';
import 'emote_source.dart';

class SevenTvSource extends ChatSource with EmoteSource, BadgeSource {
  final SevenTvApi api;

  SevenTvSource(this.api);

  @override
  String get name => '7TV';

  @override
  String? get description => null;

  @override
  Future<List<Emote>> globalEmotes() async {
    final globalEmotes = await api.globalEmotes();
    return [
      for (final emote in globalEmotes.where((emote) => emote.data.host.files.isNotEmpty))
        Emote(
          id: emote.id,
          name: emote.name,
          mipmap: mipmap(emote.data.host),
          source: this,
          flags: _isZeroWidth(emote) ? EmoteFlags.overlay : 0,
        ),
    ];
  }

  @override
  Future<List<Emote>> channelEmotes(String uid) async {
    final channelEmotes = await api.channelEmotes(uid);
    return [
      for (final emote in channelEmotes.where((emote) => emote.data.host.files.isNotEmpty))
        Emote(
          id: emote.id,
          name: emote.name,
          mipmap: mipmap(emote.data.host),
          source: this,
          flags: _isZeroWidth(emote) ? EmoteFlags.overlay : 0,
        ),
    ];
  }

  /// The emote's image URLs, smallest first. 7TV lists every size as WebP, AVIF and GIF (PNG for static emotes);
  /// WebP is the smallest Flutter can decode (it has no AVIF decoder) at the same resolution, on average less than half
  /// the size of the GIF and PNG files. Emotes without WebP files fall back to the other formats except AVIF.
  static List<String> mipmap(SevenTVEmoteDataHost host) {
    final webp = host.files.where((file) => file.format == 'WEBP');
    final files = webp.isNotEmpty ? webp : host.files.where((file) => file.format != 'AVIF');
    return [for (final file in files) 'https:${host.url}/${file.name}'];
  }

  // The emote's own ZeroWidth flag (1 << 8), or the emote set entry's (1 << 0).
  static bool _isZeroWidth(SevenTVEmote emote) => emote.data.flags & (1 << 8) != 0 || emote.flags & (1 << 0) != 0;

  @override
  Future<List<CustomBadge>> globalBadges() async => [];

  @override
  Future<List<CustomBadge>> channelBadges(String uid) async => [];

  @override
  Future<List<CustomBadge>> userBadges(String uid) async => [];

  @override
  Future<List<BadgeUsers>> globalUserBadges() async {
    final cosmetics = await api.cosmetics();
    return [
      for (final badge in cosmetics.badges)
        BadgeUsers(
          badge: CustomBadge(
            id: badge.id,
            name: badge.tooltip,
            mipmap: [
              for (final url in badge.urls) url.last,
            ],
            source: this,
          ),
          users: badge.users,
        ),
    ];
  }

  @override
  String? emoteUrl(String id) => 'https://7tv.app/emotes/$id';
}
