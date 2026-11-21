import 'dart:convert';

import 'package:coldchat/api/api_client.dart';
import 'package:coldchat/api/betterttv/betterttv.dart';
import 'package:coldchat/api/chatterino/chatterino.dart';
import 'package:coldchat/api/dankchat/dankchat.dart';
import 'package:coldchat/api/emojis/emoji_data.dart';
import 'package:coldchat/api/frankerfacez/frankerfacez.dart';
import 'package:coldchat/api/seventv/seventv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'fake_api.dart';

/// The emote, badge and emoji services: what each one requests and how it reads a typical answer.
void main() {
  late List<http.Request> requests;
  late http.Response Function(http.Request request) answer;
  late ApiClient api;

  setUp(() {
    requests = [];
    answer = (request) => http.Response('{}', 200);
    api = fakeApi(requests: requests, (request) async => answer(request));
  });

  void answerJson(Object json, [int status = 200]) =>
      answer = (request) => http.Response.bytes(utf8.encode(jsonEncode(json)), status);

  /// The one request made: a GET of [url] without a login.
  void expectGet(String url) {
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(requests.single.url, Uri.parse(url));
    expect(requests.single.headers.containsKey('Authorization'), isFalse);
  }

  group('7TV', () {
    Map<String, Object?> emote(String name, {int flags = 0}) => {
      'id': 'id-$name',
      'name': name,
      'flags': flags,
      'timestamp': 1700000000000,
      'data': {
        'id': 'id-$name',
        'name': name,
        'flags': 0,
        'lifecycle': 3,
        'state': ['LISTED'],
        'listed': true,
        'animated': false,
        'owner': null,
        'host': {
          'url': '//cdn.7tv.app/emote/id-$name',
          'files': [
            {
              'name': '1x.webp',
              'static_name': '1x_static.webp',
              'width': 32,
              'height': 32,
              'frame_count': 1,
              'size': 1000,
              'format': 'WEBP',
            },
          ],
        },
      },
    };

    test('global emotes', () async {
      answerJson({
        'id': 'global',
        'emotes': [emote('EZ'), emote('RainTime', flags: 1)],
      });

      final emotes = await SevenTvApi(api).globalEmotes();

      expectGet('https://7tv.io/v3/emote-sets/global');
      expect(emotes.map((e) => e.name), ['EZ', 'RainTime']);
      expect(emotes[1].flags, 1);
      expect(emotes[0].data.host.files.single.name, '1x.webp');
    });

    test('channel emotes', () async {
      answerJson({
        'id': 'user',
        'emote_set': {
          'emotes': [emote('forsenE')],
        },
      });

      final emotes = await SevenTvApi(api).channelEmotes('22484632');

      expectGet('https://7tv.io/v3/users/twitch/22484632');
      expect(emotes.single.name, 'forsenE');
    });

    test('a channel without an emote set has no emotes', () async {
      answerJson({'id': 'user', 'emote_set': null});

      expect(await SevenTvApi(api).channelEmotes('1'), isEmpty);
    });

    test('a Twitch user without a 7TV account (404) has no emotes', () async {
      answerJson({'status_code': 404, 'error': 'user not found', 'error_code': 12000}, 404);

      expect(await SevenTvApi(api).channelEmotes('1'), isEmpty);
    });

    test('any other failure throws, so the cached emotes are kept', () async {
      answerJson({'error': 'internal'}, 500);

      await expectLater(SevenTvApi(api).channelEmotes('1'), throwsA(isA<ApiException>()));
    });

    test('cosmetics', () async {
      answerJson({
        't': 1,
        'badges': [
          {
            'id': 'b1',
            'name': 'Admin',
            'tooltip': '7TV Admin',
            'urls': [
              ['1', 'https://cdn.7tv.app/badge/b1/1x'],
              ['2', 'https://cdn.7tv.app/badge/b1/2x'],
            ],
            'users': ['123', '456'],
          },
        ],
        'paints': <Object>[],
      });

      final cosmetics = await SevenTvApi(api).cosmetics();

      expectGet('https://7tv.io/v2/cosmetics?user_identifier=twitch_id');
      expect(cosmetics.badges.single.tooltip, '7TV Admin');
      expect(cosmetics.badges.single.users, ['123', '456']);
    });
  });

  group('BetterTTV', () {
    Map<String, Object?> emote(String code) => {'id': 'id-$code', 'code': code, 'imageType': 'png', 'animated': false};

    test('global emotes', () async {
      answerJson([emote('FeelsGoodMan'), emote('SoSnowy')]);

      final emotes = await BttvApi(api).globalEmotes();

      expectGet('https://api.betterttv.net/3/cached/emotes/global');
      expect(emotes.map((e) => e.code), ['FeelsGoodMan', 'SoSnowy']);
    });

    test('a user', () async {
      answerJson({
        'id': 'bttv-1',
        'bots': <Object>[],
        'avatar': 'https://example.com/a.png',
        'channelEmotes': [emote('forsenPls')],
        'sharedEmotes': [
          {...emote('catJAM'), 'user': <String, Object>{}},
        ],
      });

      final user = await BttvApi(api).user('22484632');

      expectGet('https://api.betterttv.net/3/cached/users/twitch/22484632');
      expect(user!.channelEmotes.single.code, 'forsenPls');
      expect(user.sharedEmotes.single.code, 'catJAM');
    });

    test('a Twitch user without a BetterTTV account (404) is null', () async {
      answerJson({'message': 'user not found'}, 404);

      expect(await BttvApi(api).user('1'), isNull);
    });

    test('badges', () async {
      answerJson([
        {
          'id': 'b1',
          'name': 'ronni',
          'displayName': 'Ronni',
          'providerId': '1337',
          'badge': {'type': 1, 'description': 'BetterTTV Developer', 'svg': 'https://cdn.betterttv.net/badge.svg'},
        },
      ]);

      final badges = await BttvApi(api).badges();

      expectGet('https://api.betterttv.net/3/cached/badges');
      expect(badges.single.providerId, '1337');
      expect(badges.single.badge.description, 'BetterTTV Developer');
    });
  });

  group('FrankerFaceZ', () {
    Map<String, Object?> emote(int id, String name) => {
      'id': id,
      'name': name,
      'height': 32,
      'width': 32,
      'public': true,
      'hidden': false,
      'modifier': false,
      'modifier_flags': 0,
      'urls': {'1': 'https://cdn.frankerfacez.com/emote/$id/1'},
      'status': 1,
      'usage_count': 10,
      'created_at': '2020-01-01T00:00:00.000Z',
      'last_updated': null,
    };

    Map<String, Object?> set(int id, List<Object?> emoticons) => {
      'id': id,
      '_type': 1,
      'title': 'Set $id',
      'emoticons': emoticons,
    };

    test('a room', () async {
      answerJson({
        'room': {'_id': 1, 'twitch_id': 22484632, 'set': 10, 'vip_badge': null, 'mod_urls': null},
        'sets': {
          '10': set(10, [emote(1, 'ZrehplaR')]),
        },
      });

      final user = await FfzApi(api).user('22484632');

      expectGet('https://api.frankerfacez.com/v1/room/id/22484632');
      expect(user.room.setId, 10);
      expect(user.sets['10']!.emoticons.single.name, 'ZrehplaR');
    });

    test('global sets', () async {
      answerJson({
        'default_sets': [3],
        'sets': {
          '3': set(3, [emote(2, 'LilZ'), emote(3, 'ZreknarF')]),
        },
      });

      final sets = await FfzApi(api).globalSets();

      expectGet('https://api.frankerfacez.com/v1/set/global');
      expect(sets.single.emoticons.map((e) => e.name), ['LilZ', 'ZreknarF']);
    });

    test('badges', () async {
      answerJson({
        'badges': [
          {
            'id': 2,
            'name': 'supporter',
            'title': 'FFZ Supporter',
            'slot': 6,
            'replaces': null,
            'color': '#755000',
            'image': 'https://cdn.frankerfacez.com/badge/2/1',
            'urls': {'1': 'https://cdn.frankerfacez.com/badge/2/1'},
            'css': null,
          },
        ],
        'users': {
          '2': [123, 456],
        },
      });

      final badges = await FfzApi(api).badges();

      expectGet('https://api.frankerfacez.com/v1/badges/ids');
      expect(badges.badges.single.title, 'FFZ Supporter');
      expect(badges.users['2'], [123, 456]);
    });

    test('a failure throws, so the cached emotes are kept', () async {
      answerJson({'error': 'Not Found', 'status': 404, 'message': 'No such room'}, 404);

      await expectLater(
        FfzApi(api).user('1'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'No such room')),
      );
    });
  });

  test('DankChat badges', () async {
    answerJson([
      {
        'type': 'DankChat Top Donator',
        'url': 'https://flxrs.com/static/badges/top.png',
        'users': ['1', '2'],
      },
    ]);

    final badges = await DankChatApi(api).badges();

    expectGet('https://flxrs.com/api/badges');
    expect(badges.single.type, 'DankChat Top Donator');
    expect(badges.single.users, ['1', '2']);
  });

  test('Chatterino badges', () async {
    // The shape api.chatterino.com/badges answers with.
    answerJson({
      'badges': [
        {
          'tooltip': 'Chatterino Top Donator',
          'image1': 'https://fourtf.com/chatterino/badges/topd.png',
          'image2': 'https://fourtf.com/chatterino/badges/topd2x.png',
          'image3': 'https://fourtf.com/chatterino/badges/topd3x.png',
          'users': ['1', '2'],
        },
        // Missing fields don't fail the list.
        {'tooltip': 'Chatterino Supporter'},
      ],
    });

    final badges = await ChatterinoApi(api).badges();

    expectGet('https://api.chatterino.com/badges');
    expect(badges.map((badge) => badge.tooltip), ['Chatterino Top Donator', 'Chatterino Supporter']);
    expect(badges.first.users, ['1', '2']);
    expect(badges.first.image3, 'https://fourtf.com/chatterino/badges/topd3x.png');
    expect(badges.last.users, isEmpty);
    expect(badges.last.image1, isNull);
  });

  test('emoji data', () async {
    answerJson([
      {'unified': '1F600', 'short_name': 'grinning', 'image': '1f600.png', 'category': 'Smileys & Emotion'},
    ]);

    final emojis = await EmojiDataApi(api).emojis();

    expectGet('https://raw.githubusercontent.com/iamcal/emoji-data/master/emoji.json');
    expect(emojis.single['short_name'], 'grinning');
    expect(
      EmojiDataApi.imageUrl('1f600.png'),
      'https://raw.githubusercontent.com/iamcal/emoji-data/master/img-twitter-72/1f600.png',
    );
  });
}
