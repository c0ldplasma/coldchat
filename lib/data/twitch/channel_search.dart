import '/api/twitch/twitch.dart';
import '/api/twitch/twitch_profile.dart';
import '/data/twitch/token_data.dart';
import '/tools/channel_ranking.dart';

/// The channel search on the home tab: Twitch's search, completed and sorted by [rankChannels].
///
/// Twitch's search also returns close misspellings, in no particular order, so with a common prefix the exact match
/// can fall outside the candidates it returns. A channel typed out exactly is therefore also looked up by login and
/// added if the search missed it. Live channels get their viewer count and game from one
/// stream lookup, which also corrects the search's live flag.
Future<List<ChannelCandidate>> searchChannels(TokenData tokenData, String rawQuery) async {
  final query = normalizeChannelQuery(rawQuery);
  if (query.isEmpty) return [];

  final (found, exactUsers) = await (
    Twitch.channelSearch(tokenData, query),
    couldBeLogin(query)
        ? Twitch.usersByLogin(tokenData, [query.toLowerCase()]).catchError((_) => <TwitchUser>[])
        : Future.value(<TwitchUser>[]),
  ).wait;

  final candidates = <String, ChannelCandidate>{
    for (final result in found)
      result.broadcasterLogin: ChannelCandidate(
        login: result.broadcasterLogin,
        displayName: result.displayName,
        profileImageUrl: result.thumbnailUrl,
        isLive: result.isLive,
      ),
  };
  for (final user in exactUsers) {
    candidates.putIfAbsent(
      user.login,
      () => ChannelCandidate(login: user.login, displayName: user.displayName, profileImageUrl: user.profileImageUrl),
    );
  }

  final toCheck = [
    for (final c in candidates.values)
      if (c.isLive || exactUsers.any((u) => u.login == c.login)) c.login,
  ].take(100).toList();
  if (toCheck.isNotEmpty) {
    try {
      final streams = {for (final s in await Twitch.streams(tokenData, userLogins: toCheck)) s.userLogin: s};
      for (final login in toCheck) {
        final candidate = candidates[login]!;
        final stream = streams[login];
        candidate.isLive = stream != null;
        candidate.viewerCount = stream?.viewerCount;
        candidate.gameName = stream?.gameName;
      }
    } catch (_) {
      // Without the stream lookup the search's own live flags still sort reasonably.
    }
  }

  return rankChannels(query, candidates.values.toList());
}
