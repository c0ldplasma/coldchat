/// A channel in the channel search, put together from Twitch's search, an exact login lookup and the live streams.
class ChannelCandidate {
  final String login;
  final String displayName;
  final String profileImageUrl;
  bool isLive;
  int? viewerCount;
  String? gameName;

  ChannelCandidate({
    required this.login,
    required this.displayName,
    required this.profileImageUrl,
    this.isLive = false,
    this.viewerCount,
    this.gameName,
  });
}

/// What the user typed, as a channel name: without surrounding spaces or a leading `#` or `@`.
String normalizeChannelQuery(String raw) => raw.trim().replaceFirst(RegExp(r'^[#@]+'), '').trim();

/// Whether [query] could be a Twitch login, so an exact lookup is worth a request.
bool couldBeLogin(String query) => RegExp(r'^[A-Za-z0-9_]{1,25}$').hasMatch(query);

/// Sorts Twitch's search results by how well they match [query]. Twitch returns them in no particular order and
/// often buries the exact match, so:
///
/// 1. the exact match (login or display name, ignoring case),
/// 2. live channels whose name starts with the query, most viewers first,
/// 3. offline channels whose name starts with the query, shortest name first,
/// 4. everything else, live before offline.
///
/// Ties keep Twitch's order.
List<ChannelCandidate> rankChannels(String query, List<ChannelCandidate> candidates) {
  final q = query.toLowerCase();
  bool exact(ChannelCandidate c) => c.login.toLowerCase() == q || c.displayName.toLowerCase() == q;
  bool prefix(ChannelCandidate c) => c.login.toLowerCase().startsWith(q) || c.displayName.toLowerCase().startsWith(q);
  int tier(ChannelCandidate c) {
    if (exact(c)) return 0;
    if (prefix(c)) return c.isLive ? 1 : 2;
    return c.isLive ? 3 : 4;
  }

  final order = {for (var i = 0; i < candidates.length; i++) candidates[i]: i};
  return [...candidates]..sort((a, b) {
      final byTier = tier(a).compareTo(tier(b));
      if (byTier != 0) return byTier;
      switch (tier(a)) {
        case 1:
          final byViewers = (b.viewerCount ?? 0).compareTo(a.viewerCount ?? 0);
          if (byViewers != 0) return byViewers;
        case 2:
          final byLength = a.login.length.compareTo(b.login.length);
          if (byLength != 0) return byLength;
      }
      return order[a]!.compareTo(order[b]!);
    });
}
