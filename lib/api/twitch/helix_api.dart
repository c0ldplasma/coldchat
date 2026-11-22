import 'package:http/http.dart' as http;

import '../../data/twitch/search_data.dart';
import '../../data/twitch/stream_data.dart';
import '../../data/twitch/token_data.dart';
import '../../data/twitch/user_data.dart';
import '../api_client.dart';
import '../json_isolate.dart';
import 'twitch.dart';
import 'twitch_badge.dart';
import 'twitch_ban_response_data.dart';
import 'twitch_emote.dart';
import 'twitch_profile.dart';

/// Twitch's Helix API (`https://api.twitch.tv/helix`), as the account whose token [tokenData] returns.
///
/// Every request carries that token and its client id. A refused request throws a [TwitchRequestException] with the
/// reason Twitch gave, a 401 the [TwitchTokenInvalidException] subtype of it. Network errors and timeouts come
/// through from [ApiClient] as they are.
class HelixApi {
  final ApiClient _api;

  /// The token requests are sent with. Read for every request, so it follows account switches.
  final TokenData? Function() tokenData;

  HelixApi(this._api, this.tokenData);

  /// The same API, as the account of [tokenData] whichever account is active.
  HelixApi forToken(TokenData tokenData) => HelixApi(_api, () => tokenData);

  /// Whether there is a token to send requests with (none while browsing anonymously).
  bool get hasToken => tokenData()?.accessToken != null;

  /// The scope [deleteChatMessage] needs. Logins from before it was requested lack it and must sign in again.
  static const String deleteChatMessageScope = 'moderator:manage:chat_messages';

  static const int _pageSize = 100;

  TokenData get _token {
    final token = tokenData();
    if (token == null || token.accessToken == null) throw StateError('No Twitch login for Helix requests');
    return token;
  }

  /// Sends [method] to `helix/[path]` with [query] (values are strings, or lists of strings for repeated
  /// parameters).
  Future<http.Response> _send(String method, String path, {Map<String, Object>? query, Object? json}) async {
    final token = _token;
    final url = Uri.https('api.twitch.tv', '/helix/$path', query == null || query.isEmpty ? null : query);
    try {
      return await _api.request(
        method,
        url,
        headers: {
          'Authorization': 'Bearer ${token.accessToken}',
          'Client-Id': '${token.clientId}',
        },
        json: json,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) throw TwitchTokenInvalidException(e.message);
      throw TwitchRequestException(e.statusCode, e.message);
    }
  }

  Future<JsonMap> _get(String path, [Map<String, Object>? query]) async =>
      ApiClient.decode(await _send('GET', path, query: query), (json) => json as JsonMap);

  /// The `data` of a GET of every page, following `pagination.cursor`.
  Future<List<dynamic>> _getAllPages(String path, Map<String, Object> query) async {
    final data = <dynamic>[];
    String? cursor;
    do {
      final page = await _get(path, {...query, 'first': '$_pageSize', 'after': ?cursor});
      data.addAll(page['data'] as List<dynamic>);
      cursor = (page['pagination'] as JsonMap?)?['cursor'] as String?;
    } while (cursor != null && cursor.isNotEmpty);
    return data;
  }

  /// The ids of the users the account has blocked.
  Future<List<String>> blockedUsers() async {
    final data = await _getAllPages('users/blocks', {'broadcaster_id': '${_token.userId}'});
    return [for (final user in data) (user as JsonMap)['user_id'] as String];
  }

  /// The account's own name and pictures.
  Future<UserData> userData() async {
    final data = ((await _get('users'))['data'] as List<dynamic>)[0] as JsonMap;
    return UserData(
      displayName: data['display_name'] as String,
      avatarUrl: data['profile_image_url'] as String,
      offlineUrl: data['offline_image_url'] as String,
    );
  }

  // Twitch shut down the unauthenticated badges.twitch.tv API, so badges come
  // from Helix, which takes any user token without extra scopes.
  Future<Map<String, Map<String, TwitchBadge>>> globalBadges() => _badges('chat/badges/global');

  Future<Map<String, Map<String, TwitchBadge>>> channelBadges(String uid) =>
      _badges('chat/badges', {'broadcaster_id': uid});

  Future<Map<String, Map<String, TwitchBadge>>> _badges(String path, [Map<String, Object>? query]) async =>
      ApiClient.decode(await _send('GET', path, query: query), _badgeSetsFromJson, inIsolate: true);

  // Static, so it can be sent to the isolate that decodes the response.
  static Map<String, Map<String, TwitchBadge>> _badgeSetsFromJson(dynamic json) =>
      twitchBadgeSetsFromJson((json as JsonMap)['data'] as List<dynamic>);

  /// Up to 100 users per request; logins that don't exist are left out.
  Future<List<TwitchUser>> usersByLogin(List<String> logins) async {
    final users = <TwitchUser>[];
    for (var i = 0; i < logins.length; i += _pageSize) {
      final json = await _get('users', {'login': logins.skip(i).take(_pageSize).toList()});
      users.addAll([for (final data in json['data'] as List<dynamic>) TwitchUser.fromJson(data as JsonMap)]);
    }
    return users;
  }

  /// Everything the user card and the channel header show, or null when the
  /// login doesn't exist. The follower total is returned for any user token;
  /// only the follower list itself needs moderator rights.
  Future<TwitchProfile?> profile(String login) async {
    final users = await usersByLogin([login]);
    if (users.isEmpty) return null;
    final user = users.first;

    final results = await Future.wait([
      _get('streams', {'user_id': user.id}),
      _get('channels/followers', {'broadcaster_id': user.id, 'first': '1'}).then<JsonMap?>(
        (json) => json,
        onError: (_) => null,
      ),
    ]);
    final streams = results[0]!['data'] as List<dynamic>;
    final followerCount = results[1]?['total'] as int?;

    TwitchLiveStream? stream;
    if (streams.isNotEmpty) {
      final data = streams.first as JsonMap;
      final gameId = data['game_id'] as String?;
      String? boxArtUrl;
      if (gameId != null && gameId.isNotEmpty) {
        try {
          final games = (await _get('games', {'id': gameId}))['data'] as List<dynamic>;
          if (games.isNotEmpty) {
            boxArtUrl = ((games.first as JsonMap)['box_art_url'] as String)
                .replaceAll('{width}', '144')
                .replaceAll('{height}', '192');
          }
        } catch (_) {
          // The cover is decoration; the card works without it.
        }
      }
      stream = TwitchLiveStream(
        title: data['title'] as String,
        gameName: data['game_name'] as String,
        gameBoxArtUrl: boxArtUrl,
        thumbnailUrl: data['thumbnail_url'] as String,
        viewerCount: data['viewer_count'] as int,
        startedAt: DateTime.parse(data['started_at'] as String),
      );
    }

    return TwitchProfile(user: user, followerCount: followerCount, stream: stream);
  }

  /// The live streams of [userLogins], or the top 100 live streams without.
  Future<List<StreamData>> streams({List<String>? userLogins}) async {
    final json = await _get('streams', {'first': '100', 'user_login': ?userLogins});
    return [for (final data in json['data'] as List<dynamic>) StreamData.fromJson(data as JsonMap)];
  }

  /// Twitch's channel search. It matches the start of the login or display name, including close misspellings, and
  /// returns them in no useful order; see `searchChannels` for what ColdChat makes of it.
  Future<List<SearchData>> channelSearch(String query, {int first = 50}) async {
    final json = await _get('search/channels', {'query': query, 'first': '$first'});
    return [for (final data in json['data'] as List<dynamic>) SearchData.fromJson(data as JsonMap)];
  }

  /// The emotes of [emoteSetIds], 25 sets per request. A request that fails is skipped rather than throwing away
  /// the emotes of every other one.
  Future<List<TwitchEmote>> emoteSets(List<String> emoteSetIds) async {
    const takeCount = 25;
    final emotes = <TwitchEmote>[];
    for (var i = 0; i < emoteSetIds.length; i += takeCount) {
      try {
        final json = await _get('chat/emotes/set', {'emote_set_id': emoteSetIds.skip(i).take(takeCount).toList()});
        emotes.addAll([for (final data in json['data'] as List<dynamic>) TwitchEmote.fromJson(data as JsonMap)]);
      } on TwitchRequestException {
        // Skip this batch.
      }
    }
    return emotes;
  }

  Future<TwitchBanResponseData> ban({
    required String broadcasterId,
    required String moderatorId,
    required String userId,
    int? duration,
    String? reason,
  }) async {
    final response = await _send(
      'POST',
      'moderation/bans',
      query: {'broadcaster_id': broadcasterId, 'moderator_id': moderatorId},
      json: {
        'data': {
          'user_id': userId,
          'duration': ?duration,
          'reason': ?reason,
        },
      },
    );
    return ApiClient.decode(
      response,
      (json) => TwitchBanResponseData.fromJson(((json as JsonMap)['data'] as List<dynamic>)[0] as JsonMap),
    );
  }

  Future<void> unban({required String broadcasterId, required String moderatorId, required String userId}) => _send(
    'DELETE',
    'moderation/bans',
    query: {'broadcaster_id': broadcasterId, 'moderator_id': moderatorId, 'user_id': userId},
  );

  /// Blocks [userId] for the account (`user:manage:blocked_users`).
  Future<void> blockUser(String userId) => _send('PUT', 'users/blocks', query: {'target_user_id': userId});

  /// Unblocks [userId] for the account (`user:manage:blocked_users`).
  Future<void> unblockUser(String userId) => _send('DELETE', 'users/blocks', query: {'target_user_id': userId});

  /// Deletes the single message [messageId] (needs [deleteChatMessageScope]). Helix deletes every message in the
  /// channel when `message_id` is missing, so an empty id is rejected instead of being sent.
  Future<void> deleteChatMessage({
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    if (messageId.isEmpty) throw ArgumentError.value(messageId, 'messageId', 'must not be empty');
    await _send(
      'DELETE',
      'moderation/chat',
      query: {'broadcaster_id': broadcasterId, 'moderator_id': moderatorId, 'message_id': messageId},
    );
  }

  Future<void> addModerator({required String broadcasterId, required String userId}) =>
      _send('POST', 'moderation/moderators', query: {'broadcaster_id': broadcasterId, 'user_id': userId});

  Future<void> removeModerator({required String broadcasterId, required String userId}) =>
      _send('DELETE', 'moderation/moderators', query: {'broadcaster_id': broadcasterId, 'user_id': userId});

  Future<void> changeChatColor({required String userId, required String color}) =>
      _send('PUT', 'chat/color', query: {'user_id': userId, 'color': color});

  Future<void> sendAnnouncement({
    required String broadcasterId,
    required String moderatorId,
    required String message,
    required String color,
  }) => _send(
    'POST',
    'chat/announcements',
    query: {'broadcaster_id': broadcasterId, 'moderator_id': moderatorId},
    json: {'message': message, 'color': color},
  );

  Future<Map<String, dynamic>> updateChatSettings({
    required String broadcasterId,
    required String moderatorId,
    bool? emoteMode,
    bool? followerMode,
    int? followerModeDuration,
    bool? nonModeratorChatDelay,
    int? nonModeratorChatDelayDuration,
    bool? slowMode,
    int? slowModeWaitTime,
    bool? subscriberMode,
    bool? uniqueChatMode,
  }) async {
    final response = await _send(
      'PATCH',
      'chat/settings',
      query: {'broadcaster_id': broadcasterId, 'moderator_id': moderatorId},
      json: {
        'emote_mode': ?emoteMode,
        'follower_mode': ?followerMode,
        'follower_mode_duration': ?followerModeDuration,
        'non_moderator_chat_delay': ?nonModeratorChatDelay,
        'non_moderator_chat_delay_duration': ?nonModeratorChatDelayDuration,
        'slow_mode': ?slowMode,
        'slow_mode_wait_time': ?slowModeWaitTime,
        'subscriber_mode': ?subscriberMode,
        'unique_chat_mode': ?uniqueChatMode,
      },
    );
    return ApiClient.decode(response, (json) => ((json as JsonMap)['data'] as List<dynamic>)[0] as JsonMap);
  }

  /// Sends a whisper from the account (`user:manage:whispers`). Twitch requires a verified phone number on the
  /// sending account and answers 204 even when it silently drops a whisper.
  Future<void> sendWhisper({required String toUserId, required String message}) => _send(
    'POST',
    'whispers',
    query: {'from_user_id': '${_token.userId}', 'to_user_id': toUserId},
    json: {'message': message},
  );

  /// Subscribes the EventSub WebSocket session [sessionId] to [type] events.
  Future<void> createEventSubSubscription({
    required String type,
    required String version,
    required Map<String, String> condition,
    required String sessionId,
  }) => _send(
    'POST',
    'eventsub/subscriptions',
    json: {
      'type': type,
      'version': version,
      'condition': condition,
      'transport': {'method': 'websocket', 'session_id': sessionId},
    },
  );
}
