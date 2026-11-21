import 'dart:async';
import 'dart:developer';

import 'package:collection/collection.dart';

import '../../api/betterttv/betterttv_socket.dart';
import '../../data/custom_badge.dart';
import '../../data/emote.dart';
import '../../sources/badge_source.dart';
import '../../sources/bttv_source.dart';
import '../../sources/chat_source.dart';
import '../../sources/emote_source.dart';
import '../badges.dart';
import '../cache.dart';
import '../emotes.dart';
import '../user_badges.dart';

/// What the chat shows in every channel: the global emotes, badges and user badges of all sources, the active
/// account's Twitch emotes and the BetterTTV Pro badges. Each list is loaded from the [cache] first, so it shows right
/// away, and then refreshed from the sources.
class ChatGlobals {
  final List<ChatSource> sources;

  /// Where the lists are kept between launches. Null in tests, then nothing is loaded or saved.
  final EmoteBadgeCache? cache;

  // Messages resolve their badges when they're built, so history inserted before the global badges arrived would
  // otherwise never show them: called when the global badges or user badges changed.
  final void Function() onBadgesChanged;

  // Called when the BetterTTV Pro badge of a user changed, so their messages are built again.
  final void Function(String userId) onUserBadgeChanged;

  final Emotes emotes = Emotes();
  final Badges badges = Badges();
  final UserBadges userBadges = UserBadges();

  /// The emotes the active account can use everywhere (subscriptions, follower emotes, …), from GLOBALUSERSTATE.
  final Emotes twitchUserEmotes = Emotes();

  /// BetterTTV Pro badges by Twitch user id. They only arrive when a Pro user opens a channel we're in, so they're kept
  /// on disk to show up on history and on later launches too.
  final Map<String, CustomBadge> bttvProBadges = {};
  late final BetterTTVSocket bttvSocket = BetterTTVSocket(onLookupUser: onBttvLookupUser);
  Timer? _saveBttvProBadgesTimer;

  /// How many BetterTTV Pro badges are kept; the users seen longest ago are dropped first.
  static const int maxBttvProBadges = 5000;

  /// Loads what the [cache] has. Nothing is requested until a refresh is called.
  ChatGlobals({
    required this.sources,
    this.cache,
    required this.onBadgesChanged,
    required this.onUserBadgeChanged,
  }) {
    final c = cache;
    if (c == null) return;
    _hydrateFromCache(c);
    c.loadBttvProBadges().forEach((userId, url) => bttvProBadges[userId] = _bttvProBadge(url));
  }

  /// Stops a pending save of the BetterTTV Pro badges.
  void close() => _saveBttvProBadgesTimer?.cancel();

  void _hydrateFromCache(EmoteBadgeCache c) {
    final emotes = c.loadEmotes(EmoteBadgeCache.globalEmotesKey);
    if (emotes.isNotEmpty) this.emotes.change(emotes);
    final badges = c.loadBadges(EmoteBadgeCache.globalBadgesKey);
    if (badges.isNotEmpty) this.badges.change(badges);
    final userBadges = c.loadUserBadges(EmoteBadgeCache.globalUserBadgesKey);
    if (userBadges.isNotEmpty) this.userBadges.change(userBadges);
  }

  Future<void> refreshEmotes() async {
    final emoteSources = sources.whereType<EmoteSource>();
    final results = await Future.wait(
      emoteSources.map((emoteSource) async {
        try {
          return await emoteSource.globalEmotes().timeout(ChatSource.timeout);
        } catch (e) {
          log('Couldn\'t get ${emoteSource.name} global emotes: $e');
          // A source that's down keeps what it gave last time, instead of its emotes disappearing until it's back.
          return [...emotes.state.where((emote) => emote.source.name == emoteSource.name)];
        }
      }),
    );
    final merged = [for (final list in results) ...list];
    emotes.change(merged);
    unawaited(cache?.saveEmotes(EmoteBadgeCache.globalEmotesKey, merged));
  }

  Future<void> refreshBadges() async {
    final badgeSources = sources.whereType<BadgeSource>();
    final results = await Future.wait(
      badgeSources.map((badgeSource) async {
        try {
          return await badgeSource.globalBadges().timeout(ChatSource.timeout);
        } catch (e) {
          log('Couldn\'t get ${badgeSource.name} global badges: $e');
          return [...badges.state.where((badge) => badge.source.name == badgeSource.name)];
        }
      }),
    );
    final merged = [for (final list in results) ...list];
    final changed = !_sameIds(badges.state.map((b) => b.id), merged.map((b) => b.id));
    badges.change(merged);
    unawaited(cache?.saveBadges(EmoteBadgeCache.globalBadgesKey, merged));
    if (changed) onBadgesChanged();
  }

  Future<void> refreshUserBadges() async {
    final badgeSources = sources.whereType<BadgeSource>();
    final results = await Future.wait(
      badgeSources.map((badgeSource) async {
        try {
          return await badgeSource.globalUserBadges().timeout(ChatSource.timeout);
        } catch (e) {
          log('Couldn\'t get ${badgeSource.name} global user badges: $e');
          return [...userBadges.state.where((users) => users.badge.source.name == badgeSource.name)];
        }
      }),
    );
    final merged = [for (final list in results) ...list];
    final changed = !UserBadges.sameHolders(userBadges.state, merged);
    userBadges.change(merged);
    unawaited(cache?.saveUserBadges(EmoteBadgeCache.globalUserBadgesKey, merged));
    if (changed) onBadgesChanged();
  }

  /// Shows the Twitch emotes the account [userId] had in the last session, or none without an account. The fresh
  /// list only arrives with GLOBALUSERSTATE after connecting, see [setTwitchUserEmotes].
  void showCachedTwitchUserEmotes(String? userId) => twitchUserEmotes.change(
    userId != null ? cache?.loadEmotes(EmoteBadgeCache.twitchUserEmotesKey(userId)) ?? [] : [],
  );

  /// Shows [emotes] as the Twitch emotes of the account [userId] and keeps them for the next launch.
  void setTwitchUserEmotes(String? userId, List<Emote> emotes) {
    twitchUserEmotes.change(emotes);
    if (userId != null) unawaited(cache?.saveEmotes(EmoteBadgeCache.twitchUserEmotesKey(userId), emotes));
  }

  CustomBadge _bttvProBadge(String url) => CustomBadge(
    id: 'bttv-pro',
    name: 'BetterTTV Pro',
    mipmap: [url],
    source: sources.whereType<BttvSource>().first,
  );

  /// BetterTTV told us whether the user in [lookup] has a Pro badge, and which.
  void onBttvLookupUser(BetterTTVProBadge lookup) {
    final url = lookup.url;
    final previous = bttvProBadges.remove(lookup.userId);
    if (url != null) {
      // Re-inserting keeps the map ordered by last sighting, so the cap below
      // drops the users seen longest ago.
      bttvProBadges[lookup.userId] = previous?.mipmap.first == url ? previous! : _bttvProBadge(url);
      while (bttvProBadges.length > maxBttvProBadges) {
        bttvProBadges.remove(bttvProBadges.keys.first);
      }
    }
    if (previous?.mipmap.first != url) onUserBadgeChanged(lookup.userId);
    _saveBttvProBadgesTimer?.cancel();
    _saveBttvProBadgesTimer = Timer(const Duration(seconds: 5), () {
      unawaited(
        cache?.saveBttvProBadges({for (final entry in bttvProBadges.entries) entry.key: entry.value.mipmap.first}),
      );
    });
  }

  static bool _sameIds(Iterable<String> a, Iterable<String> b) => const IterableEquality<String>().equals(a, b);
}
