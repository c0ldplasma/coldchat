import 'dart:convert';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/api/twitch/twitch.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../fake_api.dart';

TokenData _tokenData({String accessToken = 'access-token-1', String userId = '1337'}) => TokenData(
  clientId: 'client-id-1',
  login: 'ronni',
  scopes: const [HelixApi.deleteChatMessageScope],
  userId: userId,
  expiresAt: null,
  accessToken: accessToken,
);

http.Response _json(Object json, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(json)), status);

Map<String, Object?> _user(String id, String login) => {
  'id': id,
  'login': login,
  'display_name': login.toUpperCase(),
  'type': '',
  'broadcaster_type': 'partner',
  'description': '',
  'profile_image_url': 'https://static-cdn.jtvnw.net/$login.png',
  'offline_image_url': '',
  'created_at': '2011-05-19T00:28:28Z',
};

Map<String, Object?> _stream(String login, {int viewers = 1000, String gameId = '509658'}) => {
  'id': 's-$login',
  'user_id': 'u-$login',
  'user_login': login,
  'user_name': login.toUpperCase(),
  'game_id': gameId,
  'game_name': 'Just Chatting',
  'type': 'live',
  'title': 'hi',
  'viewer_count': viewers,
  'started_at': '2026-11-21T10:00:00Z',
  'language': 'en',
  'thumbnail_url': 'https://static-cdn.jtvnw.net/previews-ttv/live_user_$login-{width}x{height}.jpg',
  'tag_ids': <String>[],
  'tags': ['English'],
  'is_mature': false,
};

void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request request) answer;
  late HelixApi helix;

  setUp(() {
    requests = [];
    answer = (request) => http.Response('', 204);
    helix = HelixApi(fakeApi(requests: requests, (request) async => answer(request)), _tokenData);
  });

  http.Request only() {
    expect(requests, hasLength(1));
    return requests.single;
  }

  void expectHelix(http.Request request, String method, String path, [Map<String, List<String>>? query]) {
    expect(request.method, method);
    expect(request.url.scheme, 'https');
    expect(request.url.host, 'api.twitch.tv');
    expect(request.url.path, '/helix/$path');
    expect(request.url.queryParametersAll, query ?? isEmpty);
  }

  group('every request', () {
    test('carries the token and the client id', () async {
      answer = (request) => _json({'data': <Object>[]});

      await helix.streams();

      expect(only().headers['Authorization'], 'Bearer access-token-1');
      expect(only().headers['Client-Id'], 'client-id-1');
    });

    test('reads the token for each request, so it follows account switches', () async {
      var token = _tokenData();
      helix = HelixApi(fakeApi(requests: requests, (request) async => _json({'data': <Object>[]})), () => token);

      await helix.streams();
      token = _tokenData(accessToken: 'access-token-2');
      await helix.streams();

      expect(requests.map((r) => r.headers['Authorization']), ['Bearer access-token-1', 'Bearer access-token-2']);
    });

    test('forToken sends as that account', () async {
      answer = (request) => _json({'data': <Object>[]});

      await helix.forToken(_tokenData(accessToken: 'other')).streams();

      expect(only().headers['Authorization'], 'Bearer other');
    });

    test('without a login nothing is sent', () async {
      helix = HelixApi(fakeApi(requests: requests, (request) async => answer(request)), () => null);

      expect(helix.hasToken, isFalse);
      await expectLater(helix.streams(), throwsStateError);
      expect(requests, isEmpty);
    });

    test('a 401 throws a TwitchTokenInvalidException with the reason Twitch gave', () async {
      answer = (request) => _json({'error': 'Unauthorized', 'status': 401, 'message': 'Invalid OAuth token'}, 401);

      await expectLater(
        helix.streams(),
        throwsA(
          isA<TwitchTokenInvalidException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Invalid OAuth token'),
        ),
      );
    });

    test('another refusal throws a TwitchRequestException with the reason Twitch gave', () async {
      answer = (request) => _json({'error': 'Bad Request', 'status': 400, 'message': 'Malformed query params.'}, 400);

      await expectLater(
        helix.channelSearch('x'),
        throwsA(
          isA<TwitchRequestException>()
              .having((e) => e, 'not the 401 subtype', isNot(isA<TwitchTokenInvalidException>()))
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Malformed query params.'),
        ),
      );
    });

    test('a response without a JSON body throws with the HTTP status as the reason', () async {
      answer = (request) => http.Response('Bad Gateway', 502);

      await expectLater(
        helix.unblockUser('1'),
        throwsA(
          isA<TwitchRequestException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.message, 'message', 'HTTP 502'),
        ),
      );
    });
  });

  group('blockedUsers', () {
    test('follows the pagination cursor until the last page', () async {
      answer = (request) => switch (request.url.queryParameters['after']) {
        null => _json({
          'data': [
            {'user_id': '1', 'user_login': 'a', 'display_name': 'A'},
            {'user_id': '2', 'user_login': 'b', 'display_name': 'B'},
          ],
          'pagination': {'cursor': 'page2'},
        }),
        'page2' => _json({
          'data': [
            {'user_id': '3', 'user_login': 'c', 'display_name': 'C'},
          ],
          'pagination': <String, Object>{},
        }),
        _ => throw StateError('unexpected page'),
      };

      expect(await helix.blockedUsers(), ['1', '2', '3']);

      expect(requests, hasLength(2));
      expectHelix(requests[0], 'GET', 'users/blocks', {
        'broadcaster_id': ['1337'],
        'first': ['100'],
      });
      expectHelix(requests[1], 'GET', 'users/blocks', {
        'broadcaster_id': ['1337'],
        'first': ['100'],
        'after': ['page2'],
      });
    });

    test('a dead login throws instead of reading as an empty block list', () async {
      answer = (request) => _json({'status': 401, 'message': 'Invalid OAuth token'}, 401);

      await expectLater(helix.blockedUsers(), throwsA(isA<TwitchTokenInvalidException>()));
    });
  });

  group('userData', () {
    test('reads the own user', () async {
      answer = (request) => _json({
        'data': [
          {..._user('1337', 'ronni'), 'offline_image_url': 'https://static-cdn.jtvnw.net/offline.png'},
        ],
      });

      final user = await helix.userData();

      expectHelix(only(), 'GET', 'users');
      expect(user.displayName, 'RONNI');
      expect(user.avatarUrl, 'https://static-cdn.jtvnw.net/ronni.png');
      expect(user.offlineUrl, 'https://static-cdn.jtvnw.net/offline.png');
    });

    test('a refused request throws a typed error instead of a type error', () async {
      answer = (request) => _json({'status': 401, 'message': 'Invalid OAuth token'}, 401);

      await expectLater(helix.userData(), throwsA(isA<TwitchTokenInvalidException>()));
    });
  });

  test('usersByLogin asks for at most 100 logins per request', () async {
    final logins = [for (var i = 0; i < 150; i++) 'user$i'];
    answer = (request) => _json({
      'data': [for (final login in request.url.queryParametersAll['login']!) _user('id-$login', login)],
    });

    final users = await helix.usersByLogin(logins);

    expect(users.map((u) => u.login), logins);
    expect(requests, hasLength(2));
    expect(requests[0].url.queryParametersAll['login'], logins.take(100));
    expect(requests[1].url.queryParametersAll['login'], logins.skip(100));
  });

  group('profile', () {
    test('combines the user, the follower total and the live stream with its game cover', () async {
      answer = (request) => switch (request.url.path) {
        '/helix/users' => _json({
          'data': [_user('22484632', 'forsen')],
        }),
        '/helix/streams' => _json({
          'data': [_stream('forsen', viewers: 12345)],
        }),
        '/helix/channels/followers' => _json({'total': 1700000, 'data': <Object>[]}),
        '/helix/games' => _json({
          'data': [
            {'id': '509658', 'name': 'Just Chatting', 'box_art_url': 'https://x/box-{width}x{height}.jpg'},
          ],
        }),
        _ => throw StateError('unexpected ${request.url}'),
      };

      final profile = await helix.profile('forsen');

      expect(profile!.user.id, '22484632');
      expect(profile.followerCount, 1700000);
      expect(profile.stream!.viewerCount, 12345);
      expect(profile.stream!.gameBoxArtUrl, 'https://x/box-144x192.jpg');
      final urls = [for (final r in requests) r.url];
      expect(urls, contains(Uri.parse('https://api.twitch.tv/helix/users?login=forsen')));
      expect(urls, contains(Uri.parse('https://api.twitch.tv/helix/streams?user_id=22484632')));
      expect(
        urls,
        contains(Uri.parse('https://api.twitch.tv/helix/channels/followers?broadcaster_id=22484632&first=1')),
      );
      expect(urls, contains(Uri.parse('https://api.twitch.tv/helix/games?id=509658')));
    });

    test('works without the follower total and offline', () async {
      answer = (request) => switch (request.url.path) {
        '/helix/users' => _json({
          'data': [_user('1', 'ronni')],
        }),
        '/helix/streams' => _json({'data': <Object>[]}),
        _ => _json({'message': 'nope'}, 403),
      };

      final profile = await helix.profile('ronni');

      expect(profile!.followerCount, isNull);
      expect(profile.stream, isNull);
    });

    test('is null for a login that does not exist', () async {
      answer = (request) => _json({'data': <Object>[]});

      expect(await helix.profile('nobody'), isNull);
      expect(requests, hasLength(1));
    });
  });

  test('streams of some logins', () async {
    answer = (request) => _json({
      'data': [_stream('forsen'), _stream('nymn')],
      'pagination': <String, Object>{},
    });

    final streams = await helix.streams(userLogins: ['forsen', 'nymn']);

    expectHelix(only(), 'GET', 'streams', {
      'first': ['100'],
      'user_login': ['forsen', 'nymn'],
    });
    expect(streams.map((s) => s.userLogin), ['forsen', 'nymn']);
  });

  test('channelSearch', () async {
    answer = (request) => _json({
      'data': [
        {
          'broadcaster_language': 'en',
          'broadcaster_login': 'forsen',
          'display_name': 'forsen',
          'game_id': '509658',
          'game_name': 'Just Chatting',
          'id': '22484632',
          'is_live': true,
          'tag_ids': <String>[],
          'tags': ['English'],
          'thumbnail_url': 'https://static-cdn.jtvnw.net/forsen.png',
          'title': 'hi',
          'started_at': '2026-11-21T10:00:00Z',
        },
      ],
    });

    final results = await helix.channelSearch('for sen');

    expectHelix(only(), 'GET', 'search/channels', {
      'query': ['for sen'],
      'first': ['50'],
    });
    expect(results.single.broadcasterLogin, 'forsen');
    expect(results.single.isLive, isTrue);
  });

  group('emoteSets', () {
    Map<String, Object?> emote(String id, String set) => {
      'id': id,
      'name': 'emote$id',
      'images': {'url_1x': 'https://static-cdn.jtvnw.net/emoticons/v2/$id/static/light/1.0'},
      'emote_type': 'subscriptions',
      'emote_set_id': set,
      'owner_id': '1',
      'format': ['static'],
      'scale': ['1.0'],
      'theme_mode': ['light'],
    };

    test('asks for 25 sets per request and skips a batch that fails', () async {
      final sets = [for (var i = 0; i < 60; i++) 'set$i'];
      answer = (request) {
        final batch = request.url.queryParametersAll['emote_set_id']!;
        if (batch.first == 'set25') return _json({'message': 'server error'}, 500);
        return _json({
          'data': [emote(batch.first, batch.first)],
          'template': '',
        });
      };

      final emotes = await helix.emoteSets(sets);

      expect(requests.map((r) => r.url.queryParametersAll['emote_set_id']!.length), [25, 25, 10]);
      expect(emotes.map((e) => e.emoteSetId), ['set0', 'set50']);
    });
  });

  test('badges are read per set and version', () async {
    answer = (request) => _json({
      'data': [
        {
          'set_id': 'subscriber',
          'versions': [
            {
              'id': '0',
              'image_url_1x': 'https://x/1x',
              'image_url_2x': 'https://x/2x',
              'image_url_4x': 'https://x/4x',
              'title': 'Subscriber',
              'description': 'Subscriber',
              'click_action': 'subscribe_to_channel',
              'click_url': null,
            },
          ],
        },
      ],
    });

    final badges = await helix.channelBadges('22484632');

    expectHelix(only(), 'GET', 'chat/badges', {
      'broadcaster_id': ['22484632'],
    });
    expect(badges['subscriber']!['0']!.imageUrl4x, 'https://x/4x');

    requests.clear();
    await helix.globalBadges();
    expectHelix(only(), 'GET', 'chat/badges/global');
  });

  test('ban sends the user, duration and reason and reads the answer', () async {
    answer = (request) => _json({
      'data': [
        {
          'broadcaster_id': '1',
          'moderator_id': '1337',
          'user_id': '9',
          'created_at': '2026-11-21T10:00:00Z',
          'end_time': '2026-11-21T10:10:00Z',
        },
      ],
    });

    final ban = await helix.ban(broadcasterId: '1', moderatorId: '1337', userId: '9', duration: 600, reason: 'spam');

    expectHelix(only(), 'POST', 'moderation/bans', {
      'broadcaster_id': ['1'],
      'moderator_id': ['1337'],
    });
    expect(only().headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(only().body), {
      'data': {'user_id': '9', 'duration': 600, 'reason': 'spam'},
    });
    expect(ban.endTime, '2026-11-21T10:10:00Z');
  });

  test('unban', () async {
    await helix.unban(broadcasterId: '1', moderatorId: '1337', userId: '9');

    expectHelix(only(), 'DELETE', 'moderation/bans', {
      'broadcaster_id': ['1'],
      'moderator_id': ['1337'],
      'user_id': ['9'],
    });
  });

  test('block and unblock', () async {
    await helix.blockUser('9');
    await helix.unblockUser('9');

    expect(requests, hasLength(2));
    expectHelix(requests[0], 'PUT', 'users/blocks', {
      'target_user_id': ['9'],
    });
    expectHelix(requests[1], 'DELETE', 'users/blocks', {
      'target_user_id': ['9'],
    });
  });

  group('deleteChatMessage', () {
    test('sends a DELETE for exactly the one message', () async {
      await helix.deleteChatMessage(
        broadcasterId: '12826',
        moderatorId: '1337',
        messageId: 'b34ccfc7-4977-403a-8a94-33c6bac34fb8',
      );

      expectHelix(only(), 'DELETE', 'moderation/chat', {
        'broadcaster_id': ['12826'],
        'moderator_id': ['1337'],
        'message_id': ['b34ccfc7-4977-403a-8a94-33c6bac34fb8'],
      });
    });

    test('an empty message id throws before any request, as Helix would delete the whole chat', () async {
      await expectLater(
        helix.deleteChatMessage(broadcasterId: '12826', moderatorId: '1337', messageId: ''),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
    });
  });

  test('sendWhisper sends from the account to the user', () async {
    await helix.sendWhisper(toUserId: '9', message: 'hi ✨');

    expectHelix(only(), 'POST', 'whispers', {
      'from_user_id': ['1337'],
      'to_user_id': ['9'],
    });
    expect(jsonDecode(only().body), {'message': 'hi ✨'});
  });

  test('createEventSubSubscription subscribes the WebSocket session', () async {
    answer = (request) => _json({'data': <Object>[]}, 202);

    await helix.createEventSubSubscription(
      type: 'user.whisper.message',
      version: '1',
      condition: {'user_id': '1337'},
      sessionId: 'session-1',
    );

    expectHelix(only(), 'POST', 'eventsub/subscriptions');
    expect(jsonDecode(only().body), {
      'type': 'user.whisper.message',
      'version': '1',
      'condition': {'user_id': '1337'},
      'transport': {'method': 'websocket', 'session_id': 'session-1'},
    });
  });

  group('not used by the app yet', () {
    test('moderators', () async {
      await helix.addModerator(broadcasterId: '1', userId: '9');
      await helix.removeModerator(broadcasterId: '1', userId: '9');

      expectHelix(requests[0], 'POST', 'moderation/moderators', {
        'broadcaster_id': ['1'],
        'user_id': ['9'],
      });
      expectHelix(requests[1], 'DELETE', 'moderation/moderators', {
        'broadcaster_id': ['1'],
        'user_id': ['9'],
      });
    });

    test('chat color', () async {
      await helix.changeChatColor(userId: '1337', color: '#9146FF');

      expectHelix(only(), 'PUT', 'chat/color', {
        'user_id': ['1337'],
        'color': ['#9146FF'],
      });
      expect(only().url.query, contains('color=%239146FF'));
    });

    test('announcement', () async {
      await helix.sendAnnouncement(broadcasterId: '1', moderatorId: '1337', message: 'hello', color: 'purple');

      expectHelix(only(), 'POST', 'chat/announcements', {
        'broadcaster_id': ['1'],
        'moderator_id': ['1337'],
      });
      expect(jsonDecode(only().body), {'message': 'hello', 'color': 'purple'});
    });

    test('chat settings', () async {
      answer = (request) => _json({
        'data': [
          {'broadcaster_id': '1', 'slow_mode': true, 'slow_mode_wait_time': 30},
        ],
      });

      final settings = await helix.updateChatSettings(
        broadcasterId: '1',
        moderatorId: '1337',
        slowMode: true,
        slowModeWaitTime: 30,
      );

      expectHelix(only(), 'PATCH', 'chat/settings', {
        'broadcaster_id': ['1'],
        'moderator_id': ['1337'],
      });
      expect(jsonDecode(only().body), {'slow_mode': true, 'slow_mode_wait_time': 30});
      expect(settings['slow_mode_wait_time'], 30);
    });
  });
}
