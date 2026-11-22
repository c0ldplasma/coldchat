import 'dart:convert';

import 'package:coldchat/api/ivr/ivr.dart';
import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/sources/twitch_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../api/fake_api.dart';

void main() {
  late List<http.Request> requests;
  TokenData? token;
  // What Helix answers with; ivr.fi always answers with its own set.
  late int helixStatus;

  Map<String, Object> badgeSet(String setId, String url) => {
    'set_id': setId,
    'versions': [
      {
        'id': '1',
        'image_url_1x': '$url/1x',
        'image_url_2x': '$url/2x',
        'image_url_4x': '$url/4x',
        'title': 'Moderator',
        'description': 'Moderator',
      },
    ],
  };

  final api = fakeApi(requests: [], (request) async {
    requests.add(request);
    if (request.url.host == 'api.ivr.fi') {
      // ivr.fi returns the badge sets as a bare list.
      return http.Response(jsonEncode([badgeSet('vip', 'https://ivr')]), 200);
    }
    if (helixStatus != 200) return http.Response('{"message":"Unauthorized"}', helixStatus);
    return http.Response(
      jsonEncode({
        'data': [badgeSet('moderator', 'https://x')],
      }),
      200,
    );
  });

  HelixApi helix() => HelixApi(api, () => token);
  IvrApi ivr() => IvrApi(api);

  void logIn() => token = TokenData(
    clientId: 'c',
    login: 'ronni',
    scopes: const [],
    userId: '1',
    expiresAt: null,
    accessToken: 'a',
  );

  setUp(() {
    requests = [];
    token = null;
    helixStatus = 200;
  });

  test('without a login and without ivr.fi no badges are requested', () async {
    await expectLater(TwitchSource(helix: helix()).globalBadges(), throwsException);
    await expectLater(TwitchSource().channelBadges('1'), throwsException);
    expect(requests, isEmpty);
  });

  test('with a login the badges come from Helix, and nothing goes to ivr.fi', () async {
    logIn();

    final badges = await TwitchSource(helix: helix(), ivr: ivr()).channelBadges('22484632');

    expect(requests.single.url, Uri.parse('https://api.twitch.tv/helix/chat/badges?broadcaster_id=22484632'));
    expect(badges.single.id, 'moderator/1');
    expect(badges.single.mipmap, ['https://x/1x', 'https://x/2x', 'https://x/4x']);
  });

  test('without a login the badges come from ivr.fi', () async {
    final source = TwitchSource(helix: helix(), ivr: ivr());

    final channel = await source.channelBadges('22484632');
    final global = await source.globalBadges();

    expect(requests.map((r) => r.url), [
      Uri.parse('https://api.ivr.fi/v2/twitch/badges/channel?id=22484632'),
      Uri.parse('https://api.ivr.fi/v2/twitch/badges/global'),
    ]);
    expect(requests.every((r) => !r.headers.containsKey('Authorization')), isTrue);
    expect(channel.single.id, 'vip/1');
    expect(global.single.mipmap, ['https://ivr/1x', 'https://ivr/2x', 'https://ivr/4x']);
  });

  test('when Helix fails, e.g. with an expired login, the badges come from ivr.fi', () async {
    logIn();
    helixStatus = 401;

    final badges = await TwitchSource(helix: helix(), ivr: ivr()).globalBadges();

    expect(requests.map((r) => r.url.host), ['api.twitch.tv', 'api.ivr.fi']);
    expect(badges.single.id, 'vip/1');
  });

  test('when Helix fails and there is no ivr.fi, the error comes through', () async {
    logIn();
    helixStatus = 500;

    await expectLater(TwitchSource(helix: helix()).globalBadges(), throwsA(anything));
  });
}
