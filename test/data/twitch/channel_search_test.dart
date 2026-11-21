import 'dart:convert';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/data/twitch/channel_search.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/tools/channel_ranking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../api/fake_api.dart';

TokenData _tokenData() => TokenData(
  clientId: 'client-id-1',
  login: 'ronni',
  scopes: const [],
  userId: '1337',
  expiresAt: null,
  accessToken: 'access-token-1',
);

http.Response _json(Object json, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(json)), status);

Map<String, Object?> _searchResult(String login, {bool live = false}) => {
  'broadcaster_language': 'en',
  'broadcaster_login': login,
  'display_name': login.toUpperCase(),
  'game_id': '',
  'game_name': '',
  'id': 'u-$login',
  'is_live': live,
  'tag_ids': <String>[],
  'tags': <String>[],
  'thumbnail_url': 'https://static-cdn.jtvnw.net/$login.png',
  'title': '',
  'started_at': '',
};

Map<String, Object?> _user(String login) => {
  'id': 'u-$login',
  'login': login,
  'display_name': login.toUpperCase(),
  'type': '',
  'broadcaster_type': '',
  'description': '',
  'profile_image_url': 'https://static-cdn.jtvnw.net/user-$login.png',
  'offline_image_url': '',
  'created_at': '2011-05-19T00:28:28Z',
};

Map<String, Object?> _stream(String login, {int viewers = 1000, String game = 'Just Chatting'}) => {
  'id': 's-$login',
  'user_id': 'u-$login',
  'user_login': login,
  'user_name': login.toUpperCase(),
  'game_id': '509658',
  'game_name': game,
  'type': 'live',
  'title': 'hi',
  'viewer_count': viewers,
  'started_at': '2026-11-21T10:00:00Z',
  'language': 'en',
  'thumbnail_url': '',
  'tag_ids': <String>[],
  'tags': <String>[],
  'is_mature': false,
};

void main() {
  late List<http.Request> requests;
  late List<Map<String, Object?>> searchResults;
  late List<Map<String, Object?>> users;
  late List<Map<String, Object?>> streams;
  late bool streamsFail;
  late HelixApi helix;

  setUp(() {
    requests = [];
    searchResults = [];
    users = [];
    streams = [];
    streamsFail = false;
    helix = HelixApi(
      fakeApi(requests: requests, (request) async {
        final query = request.url.queryParametersAll;
        switch (request.url.path) {
          case '/helix/search/channels':
            return _json({'data': searchResults});
          case '/helix/users':
            return _json({
              'data': [
                for (final u in users)
                  if (query['login']!.contains(u['login'])) u,
              ],
            });
          case '/helix/streams':
            if (streamsFail) return _json({'error': 'Internal Server Error', 'status': 500, 'message': ''}, 500);
            return _json({
              'data': [
                for (final s in streams)
                  if (query['user_login']!.contains(s['user_login'])) s,
              ],
            });
        }
        return http.Response('', 404);
      }),
      _tokenData,
    );
  });

  List<String> paths() => [for (final r in requests) r.url.path];
  List<String> logins(List<ChannelCandidate> results) => [for (final c in results) c.login];

  test('an empty query sends no request', () async {
    expect(await searchChannels(helix, ' #@ '), isEmpty);
    expect(requests, isEmpty);
  });

  test('searches the normalized query and looks the login up in lower case', () async {
    await searchChannels(helix, ' #ForSen ');
    final search = requests.singleWhere((r) => r.url.path == '/helix/search/channels');
    expect(search.url.queryParameters['query'], 'ForSen');
    final lookup = requests.singleWhere((r) => r.url.path == '/helix/users');
    expect(lookup.url.queryParametersAll['login'], ['forsen']);
  });

  test('a query that cannot be a login is only searched', () async {
    searchResults = [_searchResult('somestreamer')];
    expect(logins(await searchChannels(helix, 'some streamer')), ['somestreamer']);
    expect(paths(), ['/helix/search/channels']);
  });

  test('adds the exact login when the search missed it, and ranks it first', () async {
    searchResults = [_searchResult('forsenbajs', live: true), _searchResult('forsenlol')];
    users = [_user('forsen')];
    streams = [_stream('forsenbajs', viewers: 50)];

    final results = await searchChannels(helix, 'forsen');
    expect(logins(results), ['forsen', 'forsenbajs', 'forsenlol']);
    expect(results.first.displayName, 'FORSEN');
    expect(results.first.profileImageUrl, 'https://static-cdn.jtvnw.net/user-forsen.png');
  });

  test('does not add the exact login twice when the search found it', () async {
    searchResults = [_searchResult('forsenbajs'), _searchResult('forsen')];
    users = [_user('forsen')];

    final results = await searchChannels(helix, 'forsen');
    expect(logins(results), ['forsen', 'forsenbajs']);
    // The search's thumbnail is kept.
    expect(results.first.profileImageUrl, 'https://static-cdn.jtvnw.net/forsen.png');
  });

  test('the stream lookup corrects the live flags and adds viewers and game', () async {
    searchResults = [
      _searchResult('forc', live: true),
      _searchResult('forb', live: true),
      _searchResult('fora', live: true),
    ];
    users = [_user('for')];
    // forb went offline, the exact match "for" is live although the search did not return it.
    streams = [_stream('fora', viewers: 10), _stream('forc', viewers: 500, game: 'Chess'), _stream('for')];

    final results = await searchChannels(helix, 'for');
    final lookup = requests.singleWhere((r) => r.url.path == '/helix/streams');
    expect(lookup.url.queryParametersAll['user_login'], unorderedEquals(['forc', 'forb', 'fora', 'for']));

    expect(logins(results), ['for', 'forc', 'fora', 'forb']);
    final byLogin = {for (final c in results) c.login: c};
    expect(byLogin['for']!.isLive, isTrue);
    expect(byLogin['forc']!.viewerCount, 500);
    expect(byLogin['forc']!.gameName, 'Chess');
    expect(byLogin['forb']!.isLive, isFalse);
    expect(byLogin['forb']!.viewerCount, isNull);
  });

  test('offline search results are not looked up', () async {
    searchResults = [_searchResult('forsenbajs')];

    await searchChannels(helix, 'forsen');
    expect(paths(), isNot(contains('/helix/streams')));
  });

  test('a failed stream lookup keeps the search live flags', () async {
    searchResults = [_searchResult('forsenlol'), _searchResult('forsenbajs', live: true)];
    users = [_user('forsen')];
    streamsFail = true;

    final results = await searchChannels(helix, 'forsen');
    expect(logins(results), ['forsen', 'forsenbajs', 'forsenlol']);
    expect(results[1].isLive, isTrue);
    expect(results[1].viewerCount, isNull);
  });

  test('a failed login lookup still returns the search results', () async {
    searchResults = [_searchResult('forsenbajs')];
    helix = HelixApi(
      fakeApi((request) async {
        if (request.url.path == '/helix/users') return _json({'message': 'boom'}, 500);
        return _json({'data': searchResults});
      }),
      _tokenData,
    );

    expect(logins(await searchChannels(helix, 'forsen')), ['forsenbajs']);
  });

  test('a failed search fails', () async {
    helix = HelixApi(fakeApi((request) async => _json({'message': 'boom'}, 500)), _tokenData);

    await expectLater(searchChannels(helix, 'forsen'), throwsA(anything));
  });
}
