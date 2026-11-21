import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/twitch/search_data.dart';
import '../../data/twitch/stream_data.dart';
import '../../data/twitch/token_data.dart';
import '../../data/twitch/user_data.dart';
import '../json_isolate.dart';
import 'twitch_badge.dart';
import 'twitch_ban_response_data.dart';
import 'twitch_emote.dart';
import 'twitch_profile.dart';

Map<String, Map<String, TwitchBadge>> _badgeSetsFromJson(dynamic json) => {
  for (final badgeSet in (json as JsonMap)['data'] as List<dynamic>)
    (badgeSet as JsonMap)['set_id'] as String: {
      for (final badgeVersion in badgeSet['versions'] as List<dynamic>)
        (badgeVersion as JsonMap)['id'] as String: TwitchBadge.fromJson(badgeVersion),
    },
};

/// Thrown when Twitch rejects an access token (401 from /oauth2/validate).
/// Distinct from a generic failure so callers can tell "the login is dead, ask
/// the user to sign in again" apart from "the network is down, try later".
class TwitchTokenInvalidException implements Exception {
  final String message;

  TwitchTokenInvalidException([this.message = 'The access token is no longer valid']);

  @override
  String toString() => 'TwitchTokenInvalidException: $message';
}

/// A Helix request Twitch refused, with the reason Twitch gave. Its [message] is meant to be shown to the user.
class TwitchRequestException implements Exception {
  final int statusCode;
  final String message;

  TwitchRequestException(this.statusCode, this.message);

  @override
  String toString() => 'TwitchRequestException($statusCode): $message';
}

class Twitch {
  static Future<List<String>> blockedUsers(TokenData tokenData) async {
    try {
      final result = <String>[];
      const pageSize = 100;
      String? cursor;

      do {
        final response = await http.get(
          Uri.parse(
            'https://api.twitch.tv/helix/users/blocks?broadcaster_id=${tokenData.userId}&first=$pageSize${cursor != null ? '&after=$cursor' : ''}',
          ),
          headers: {
            'Authorization': 'Bearer ${tokenData.accessToken}',
            'Client-Id': '${tokenData.clientId}',
          },
        );
        final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
        final data = List<dynamic>.from(responseJson['data'] as List<dynamic>);
        result.addAll(data.map((e) => (e as JsonMap)['user_id'] as String));
        cursor = (responseJson['pagination'] as JsonMap?)?['cursor'] as String?;
        // if (data.length < pageSize) break;
      } while (cursor != null);

      return result;
    } catch (e) {
      return [];
    }
  }

  static Future<TokenData> validateToken(String token) async {
    final response = await http.get(
      Uri.parse('https://id.twitch.tv/oauth2/validate'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
    // A rejected token answers 401 with {status, message} and no login/client_id,
    // which used to blow up on the non-nullable `login` further down. Surface it
    // as a typed error instead so callers can react to an expired login.
    if (response.statusCode == 401) {
      throw TwitchTokenInvalidException(responseJson['message'] as String? ?? 'invalid access token');
    }
    if (response.statusCode != 200) {
      throw Exception('Token validation failed (${response.statusCode}): ${responseJson['message']}');
    }
    return TokenData(
      clientId: responseJson['client_id'] as String?,
      login: responseJson['login'] as String,
      scopes: List<String>.from(responseJson['scopes'] as List<dynamic>? ?? <dynamic>[]),
      userId: responseJson['user_id'] as String?,
      expiresAt: responseJson['expires_in'] == 0
          ? null
          : DateTime.now().add(
              Duration(seconds: responseJson['expires_in'] as int),
            ),
      accessToken: token,
    );
  }

  static Future<UserData> userData(TokenData tokenData) async {
    final response = await http.get(
      Uri.parse('https://api.twitch.tv/helix/users'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );
    final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
    final data = (responseJson['data'] as List<dynamic>)[0] as JsonMap;
    return UserData(
      displayName: data['display_name'] as String,
      avatarUrl: data['profile_image_url'] as String,
      offlineUrl: data['offline_image_url'] as String,
    );
  }

  // Twitch shut down the unauthenticated badges.twitch.tv API, so badges come
  // from Helix, which takes any user token without extra scopes.
  static Future<Map<String, Map<String, TwitchBadge>>> globalBadges(TokenData tokenData) {
    return _badges(tokenData, Uri.parse('https://api.twitch.tv/helix/chat/badges/global'));
  }

  static Future<Map<String, Map<String, TwitchBadge>>> channelBadges(TokenData tokenData, String uid) {
    return _badges(tokenData, Uri.parse('https://api.twitch.tv/helix/chat/badges?broadcaster_id=$uid'));
  }

  static Future<Map<String, Map<String, TwitchBadge>>> _badges(TokenData tokenData, Uri uri) async {
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );
    if (response.statusCode != 200) throw Exception('Twitch badges request failed with HTTP ${response.statusCode}');
    return decodeJsonInIsolate(response.bodyBytes, _badgeSetsFromJson);
  }

  static Future<JsonMap> _helixGet(TokenData tokenData, String pathAndQuery) async {
    final response = await http.get(
      Uri.parse('https://api.twitch.tv/helix/$pathAndQuery'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Twitch request $pathAndQuery failed with HTTP ${response.statusCode}');
    }
    return json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
  }

  /// Up to 100 users per request; logins that don't exist are left out.
  static Future<List<TwitchUser>> usersByLogin(TokenData tokenData, List<String> logins) async {
    final users = <TwitchUser>[];
    for (var i = 0; i < logins.length; i += 100) {
      final batch = logins.skip(i).take(100).map((login) => 'login=${Uri.encodeQueryComponent(login)}').join('&');
      final responseJson = await _helixGet(tokenData, 'users?$batch');
      users.addAll([for (final data in responseJson['data'] as List<dynamic>) TwitchUser.fromJson(data as JsonMap)]);
    }
    return users;
  }

  /// Everything the user card and the channel header show, or null when the
  /// login doesn't exist. The follower total is returned for any user token;
  /// only the follower list itself needs moderator rights.
  static Future<TwitchProfile?> profile(TokenData tokenData, String login) async {
    final users = await usersByLogin(tokenData, [login]);
    if (users.isEmpty) return null;
    final user = users.first;

    final results = await Future.wait([
      _helixGet(tokenData, 'streams?user_id=${user.id}'),
      _helixGet(
        tokenData,
        'channels/followers?broadcaster_id=${user.id}&first=1',
      ).then<JsonMap?>((json) => json, onError: (_) => null),
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
          final games = (await _helixGet(tokenData, 'games?id=$gameId'))['data'] as List<dynamic>;
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

  static Future<List<StreamData>> streams(
    TokenData tokenData, {
    List<String>? userLogins,
  }) async {
    final response = await http.get(
      Uri.parse(
        'https://api.twitch.tv/helix/streams?first=100${userLogins != null ? '&${userLogins.map((e) => 'user_login=${Uri.encodeQueryComponent(e)}').join('&')}' : ''}',
      ),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );
    final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
    return [
      for (final data in responseJson['data'] as List<dynamic>) StreamData.fromJson(data as JsonMap),
    ];
  }

  /// Twitch's channel search. It matches the start of the login or display name, including close misspellings, and
  /// returns them in no useful order; see `searchChannels` for what ColdChat makes of it.
  static Future<List<SearchData>> channelSearch(TokenData tokenData, String query, {int first = 50}) async {
    final response = await http.get(
      Uri.https('api.twitch.tv', '/helix/search/channels', {'query': query, 'first': '$first'}),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );
    final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
    return [
      for (final data in responseJson['data'] as List<dynamic>) SearchData.fromJson(data as JsonMap),
    ];
  }

  static Future<List<TwitchEmote>> emoteSets(TokenData tokenData, List<String> emoteSetIds) async {
    const takeCount = 25;
    final emotes = <TwitchEmote>[];
    while (emoteSetIds.isNotEmpty) {
      final emoteSetsPack = emoteSetIds.take(takeCount).toList();
      final response = await http.get(
        Uri.parse(
          'https://api.twitch.tv/helix/chat/emotes/set?${emoteSetsPack.map((x) => 'emote_set_id=$x').join('&')}',
        ),
        headers: {
          'Authorization': 'Bearer ${tokenData.accessToken}',
          'Client-Id': '${tokenData.clientId}',
        },
      );
      // Skip a batch that fails rather than throwing away the emotes from
      // every other batch.
      if (response.statusCode == 200) {
        final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
        emotes.addAll([
          for (final data in responseJson['data'] as List<dynamic>) TwitchEmote.fromJson(data as JsonMap),
        ]);
      }
      emoteSetIds.removeRange(0, emoteSetsPack.length);
    }
    return emotes;
  }

  static Future<TwitchBanResponseData> ban(
    TokenData tokenData, {
    required String broadcasterId,
    required String moderatorId,
    required String userId,
    int? duration,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.twitch.tv/helix/moderation/bans?broadcaster_id=$broadcasterId&moderator_id=$moderatorId'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'data': {
          'user_id': userId,
          'duration': ?duration,
          'reason': ?reason,
        },
      }),
    );

    if (response.statusCode == 200) {
      final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      return TwitchBanResponseData.fromJson((responseJson['data'] as List<dynamic>)[0] as JsonMap);
    } else {
      throw _requestException(response);
    }
  }

  static Future<void> unban(
    TokenData tokenData, {
    required String broadcasterId,
    required String moderatorId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        'https://api.twitch.tv/helix/moderation/bans?broadcaster_id=$broadcasterId&moderator_id=$moderatorId&user_id=$userId',
      ),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );

    if (response.statusCode != 204) throw _requestException(response);
  }

  /// Blocks [userId] for the account of [tokenData] (`user:manage:blocked_users`).
  static Future<void> blockUser(TokenData tokenData, String userId) => _blocks(tokenData, userId, http.put);

  /// Unblocks [userId] for the account of [tokenData] (`user:manage:blocked_users`).
  static Future<void> unblockUser(TokenData tokenData, String userId) => _blocks(tokenData, userId, http.delete);

  static Future<void> _blocks(
    TokenData tokenData,
    String userId,
    Future<http.Response> Function(Uri url, {Map<String, String>? headers}) method,
  ) async {
    final response = await method(
      Uri.parse('https://api.twitch.tv/helix/users/blocks?target_user_id=$userId'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );

    if (response.statusCode != 204) {
      final errorJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      throw Exception('${errorJson['error']}: ${errorJson['message']}');
    }
  }

  /// The scope [deleteChatMessage] needs. Logins from before it was requested lack it and must sign in again.
  static const String deleteChatMessageScope = 'moderator:manage:chat_messages';

  /// Deletes the single message [messageId] (needs [deleteChatMessageScope]). Helix deletes every message in the
  /// channel when `message_id` is missing, so an empty id is rejected instead of being sent.
  static Future<void> deleteChatMessage(
    TokenData tokenData, {
    required String broadcasterId,
    required String moderatorId,
    required String messageId,
  }) async {
    if (messageId.isEmpty) throw ArgumentError.value(messageId, 'messageId', 'must not be empty');
    final response = await http.delete(
      Uri.https('api.twitch.tv', '/helix/moderation/chat', {
        'broadcaster_id': broadcasterId,
        'moderator_id': moderatorId,
        'message_id': messageId,
      }),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );

    if (response.statusCode != 204) throw _requestException(response);
  }

  static Future<void> addModerator(
    TokenData tokenData, {
    required String broadcasterId,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.twitch.tv/helix/moderation/moderators?broadcaster_id=$broadcasterId&user_id=$userId'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );

    if (response.statusCode != 204) {
      final errorJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      throw Exception('${errorJson['error']}: ${errorJson['message']}');
    }
  }

  static Future<void> removeModerator(
    TokenData tokenData, {
    required String broadcasterId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('https://api.twitch.tv/helix/moderation/moderators?broadcaster_id=$broadcasterId&user_id=$userId'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );

    if (response.statusCode != 204) {
      final errorJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      throw Exception('${errorJson['error']}: ${errorJson['message']}');
    }
  }

  static Future<void> changeChatColor(
    TokenData tokenData, {
    required String userId,
    required String color,
  }) async {
    final response = await http.put(
      Uri.parse('https://api.twitch.tv/helix/chat/color?user_id=$userId&color=${Uri.encodeComponent(color)}'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
      },
    );

    if (response.statusCode != 204) {
      final errorJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      throw Exception('${errorJson['error']}: ${errorJson['message']}');
    }
  }

  static Future<void> sendAnnouncement(
    TokenData tokenData, {
    required String broadcasterId,
    required String moderatorId,
    required String message,
    required String color,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://api.twitch.tv/helix/chat/announcements?broadcaster_id=$broadcasterId&moderator_id=$moderatorId',
      ),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'message': message,
        'color': color,
      }),
    );

    if (response.statusCode != 204) {
      final errorJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      throw Exception('${errorJson['error']}: ${errorJson['message']}');
    }
  }

  static Future<Map<String, dynamic>> updateChatSettings(
    TokenData tokenData, {
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
    final settings = {
      'emote_mode': ?emoteMode,
      'follower_mode': ?followerMode,
      'follower_mode_duration': ?followerModeDuration,
      'non_moderator_chat_delay': ?nonModeratorChatDelay,
      'non_moderator_chat_delay_duration': ?nonModeratorChatDelayDuration,
      'slow_mode': ?slowMode,
      'slow_mode_wait_time': ?slowModeWaitTime,
      'subscriber_mode': ?subscriberMode,
      'unique_chat_mode': ?uniqueChatMode,
    };

    final response = await http.patch(
      Uri.parse('https://api.twitch.tv/helix/chat/settings?broadcaster_id=$broadcasterId&moderator_id=$moderatorId'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
        'Content-Type': 'application/json',
      },
      body: json.encode(settings),
    );

    if (response.statusCode == 200) {
      final responseJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      return (responseJson['data'] as List<dynamic>)[0] as JsonMap;
    } else {
      final errorJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      throw Exception('${errorJson['error']}: ${errorJson['message']}');
    }
  }

  /// Sends a whisper from the account of [tokenData] (`user:manage:whispers`). Twitch requires a verified
  /// phone number on the sending account and answers 204 even when it silently drops a whisper.
  static Future<void> sendWhisper(TokenData tokenData, {required String toUserId, required String message}) async {
    final response = await http.post(
      Uri.parse('https://api.twitch.tv/helix/whispers?from_user_id=${tokenData.userId}&to_user_id=$toUserId'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
        'Content-Type': 'application/json',
      },
      body: json.encode({'message': message}),
    );
    if (response.statusCode != 204) throw _requestException(response);
  }

  /// Subscribes the EventSub WebSocket session [sessionId] to [type] events.
  static Future<void> createEventSubSubscription(
    TokenData tokenData, {
    required String type,
    required String version,
    required Map<String, String> condition,
    required String sessionId,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.twitch.tv/helix/eventsub/subscriptions'),
      headers: {
        'Authorization': 'Bearer ${tokenData.accessToken}',
        'Client-Id': '${tokenData.clientId}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'type': type,
        'version': version,
        'condition': condition,
        'transport': {'method': 'websocket', 'session_id': sessionId},
      }),
    );
    if (response.statusCode != 202) throw _requestException(response);
  }

  static TwitchRequestException _requestException(http.Response response) {
    try {
      final errorJson = json.decode(utf8.decode(response.bodyBytes)) as JsonMap;
      return TwitchRequestException(response.statusCode, '${errorJson['message'] ?? errorJson['error']}');
    } catch (_) {
      return TwitchRequestException(response.statusCode, 'HTTP ${response.statusCode}');
    }
  }
}
