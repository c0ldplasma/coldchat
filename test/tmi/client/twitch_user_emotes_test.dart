import 'dart:convert';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/api/twitch/twitch_badge.dart';
import 'package:coldchat/api/twitch/twitch_emote.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/tmi/client/twitch_user_emotes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../api/fake_api.dart';

class _Source extends ChatSource {
  @override
  String get name => 'Twitch';

  @override
  String? get description => null;
}

final _twitch = _Source();

Map<String, Object?> _emoteJson(String name, {String type = 'subscriptions', String owner = '0', String set = 's'}) => {
  'id': name,
  'name': name,
  'images': {'url_1x': 'https://static-cdn.jtvnw.net/$name/1.0'},
  'emote_type': type,
  'emote_set_id': set,
  'owner_id': owner,
  'format': ['static'],
  'scale': ['1.0'],
  'theme_mode': ['light'],
};

TwitchEmote _emote(String name, {String type = 'subscriptions', String owner = '0'}) =>
    TwitchEmote.fromJson(_emoteJson(name, type: type, owner: owner));

TwitchBadge _badge(String url) =>
    TwitchBadge(imageUrl1x: '$url/1', imageUrl2x: '$url/2', imageUrl4x: '$url/4', description: null, title: 'Sub');

/// The sections the emotes go into, by category (null: the Twitch section), with their names and icons.
List<(String?, String, String?)> _described(List<Emote> emotes) => [
  for (final emote in emotes) (emote.category, emote.name, emote.categoryIcon),
];

http.Response _json(Object json, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(json)), status);

void main() {
  group('channelOwnerOf', () {
    test('is the owner of sub, follower and Bits emotes', () {
      expect(channelOwnerOf(_emote('ronniHi', owner: '42')), '42');
      expect(channelOwnerOf(_emote('ronniFollow', type: 'follower', owner: '42')), '42');
      expect(channelOwnerOf(_emote('ronniBits', type: 'bitstier', owner: '42')), '42');
    });

    test('is null for Twitch\'s own emotes', () {
      expect(channelOwnerOf(_emote('Kappa', type: 'globals', owner: '0')), isNull);
      expect(channelOwnerOf(_emote('KappaHD', type: 'turbo', owner: '0')), isNull);
      expect(channelOwnerOf(_emote('HypeCheer', type: 'hypetrain', owner: 'twitch')), isNull);
      expect(channelOwnerOf(_emote('weird', owner: '0')), isNull);
      expect(channelOwnerOf(_emote('weird', owner: 'twitch')), isNull);
    });
  });

  group('subscriberBadgeUrl', () {
    test('is the base tier 1 badge, the lowest month count below the tier 2 and 3 versions', () {
      expect(
        subscriberBadgeUrl({
          'subscriber': {'2000': _badge('t2'), '12': _badge('m12'), '3': _badge('m3'), '0': _badge('m0')},
        }),
        'm0/4',
      );
      expect(
        subscriberBadgeUrl({
          'subscriber': {'2003': _badge('t2'), '6': _badge('m6'), '3': _badge('m3')},
        }),
        'm3/4',
      );
    });

    test('takes any version when there is no tier 1 one, and is null without subscriber badges', () {
      expect(
        subscriberBadgeUrl({
          'subscriber': {'3000': _badge('t3')},
        }),
        't3/4',
      );
      expect(
        subscriberBadgeUrl({
          'bits': {'1': _badge('b')},
        }),
        isNull,
      );
      expect(subscriberBadgeUrl({}), isNull);
    });
  });

  group('twitchUserEmotesFrom', () {
    test('puts each channel\'s emotes in a section named after it, by name after the other emotes', () {
      final emotes = twitchUserEmotesFrom(
        [
          _emote('zzzHi', owner: '2'),
          _emote('Kappa', type: 'globals'),
          _emote('ronniHi', owner: '1'),
          _emote('zzzFollow', type: 'follower', owner: '2'),
          _emote('KappaHD', type: 'turbo'),
          _emote('ronniBye', owner: '1'),
        ],
        _twitch,
        ownerNames: {'1': 'Ronni', '2': 'aaa'},
        ownerBadges: {'1': 'https://badge/ronni'},
      );

      expect(_described(emotes), [
        (null, 'Kappa', null),
        (null, 'KappaHD', null),
        ('aaa', 'zzzHi', null),
        ('aaa', 'zzzFollow', null),
        ('Ronni', 'ronniHi', 'https://badge/ronni'),
        ('Ronni', 'ronniBye', 'https://badge/ronni'),
      ]);
      expect(emotes.map((emote) => emote.source), everyElement(same(_twitch)));
      expect(emotes.first.mipmap, ['https://static-cdn.jtvnw.net/Kappa/1.0']);
    });

    test('keeps the emotes of a channel whose name is unknown in the Twitch section', () {
      final emotes = twitchUserEmotesFrom(
        [_emote('Kappa', type: 'globals'), _emote('ronniHi', owner: '1')],
        _twitch,
        ownerBadges: {'1': 'https://badge/ronni'},
      );

      expect(_described(emotes), [(null, 'Kappa', null), (null, 'ronniHi', null)]);
    });
  });

  group('loadTwitchUserEmotes', () {
    late List<http.Request> requests;
    late Future<http.Response> Function(http.Request request) answer;
    late HelixApi helix;

    setUp(() {
      requests = [];
      helix = HelixApi(
        fakeApi(requests: requests, (request) => answer(request)),
        () => TokenData(
          clientId: 'client',
          login: 'moddy',
          scopes: const [],
          userId: '9',
          expiresAt: null,
          accessToken: 'token',
        ),
      );
    });

    Map<String, Object?> user(String id, String name) => {
      'id': id,
      'login': name.toLowerCase(),
      'display_name': name,
      'type': '',
      'broadcaster_type': 'partner',
      'description': '',
      'profile_image_url': '',
      'offline_image_url': '',
      'created_at': '2011-05-19T00:28:28Z',
    };

    Map<String, Object?> subscriberBadges(String url) => {
      'set_id': 'subscriber',
      'versions': [
        {
          'id': '0',
          'image_url_1x': '$url/1',
          'image_url_2x': '$url/2',
          'image_url_4x': '$url/4',
          'title': 'Subscriber',
          'description': 'Subscriber',
        },
      ],
    };

    test('looks up the names and subscriber badges of the channels the emotes belong to', () async {
      answer = (request) async => switch (request.url.path) {
        '/helix/chat/emotes/set' => _json({
          'data': [
            _emoteJson('Kappa', type: 'globals'),
            _emoteJson('ronniHi', owner: '1'),
            _emoteJson('aaaHi', owner: '2'),
          ],
        }),
        '/helix/users' => _json({
          'data': [user('1', 'Ronni'), user('2', 'aaa')],
        }),
        // Channel 2's badges fail: its section goes without the badge.
        '/helix/chat/badges' when request.url.queryParameters['broadcaster_id'] == '1' => _json({
          'data': [subscriberBadges('https://badge/ronni')],
        }),
        _ => _json({'message': 'server error'}, 500),
      };

      final emotes = await loadTwitchUserEmotes(helix, ['0', 's1'], _twitch);

      expect(_described(emotes), [
        (null, 'Kappa', null),
        ('aaa', 'aaaHi', null),
        ('Ronni', 'ronniHi', 'https://badge/ronni/4'),
      ]);
      final users = requests.singleWhere((request) => request.url.path == '/helix/users');
      expect(users.url.queryParametersAll['id'], ['1', '2']);
      expect(
        requests.where((r) => r.url.path == '/helix/chat/badges').map((r) => r.url.queryParameters['broadcaster_id']),
        unorderedEquals(['1', '2']),
      );
    });

    test('keeps the emotes in the Twitch section when the names can\'t be loaded', () async {
      answer = (request) async => switch (request.url.path) {
        '/helix/chat/emotes/set' => _json({
          'data': [_emoteJson('ronniHi', owner: '1')],
        }),
        _ => _json({'message': 'server error'}, 500),
      };

      final emotes = await loadTwitchUserEmotes(helix, ['s1'], _twitch);

      expect(_described(emotes), [(null, 'ronniHi', null)]);
    });

    test('asks for no names or badges without channel emotes', () async {
      answer = (request) async => _json({
        'data': [_emoteJson('Kappa', type: 'globals')],
      });

      final emotes = await loadTwitchUserEmotes(helix, ['0'], _twitch);

      expect(_described(emotes), [(null, 'Kappa', null)]);
      expect(requests.map((request) => request.url.path), ['/helix/chat/emotes/set']);
    });
  });
}
