import 'dart:convert';

import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/sources/twitch_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../api/fake_api.dart';

void main() {
  late List<http.Request> requests;
  TokenData? token;

  HelixApi helix() => HelixApi(
    fakeApi(
      requests: requests,
      (request) async => http.Response(
        jsonEncode({
          'data': [
            {
              'set_id': 'moderator',
              'versions': [
                {
                  'id': '1',
                  'image_url_1x': 'https://x/1x',
                  'image_url_2x': 'https://x/2x',
                  'image_url_4x': 'https://x/4x',
                  'title': 'Moderator',
                  'description': 'Moderator',
                },
              ],
            },
          ],
        }),
        200,
      ),
    ),
    () => token,
  );

  setUp(() {
    requests = [];
    token = null;
  });

  test('without a login no badges are requested', () async {
    await expectLater(TwitchSource(helix: helix()).globalBadges(), throwsException);
    await expectLater(TwitchSource().channelBadges('1'), throwsException);
    expect(requests, isEmpty);
  });

  test('with a login the badges come from Helix', () async {
    token = TokenData(
      clientId: 'c',
      login: 'ronni',
      scopes: const [],
      userId: '1',
      expiresAt: null,
      accessToken: 'a',
    );

    final badges = await TwitchSource(helix: helix()).channelBadges('22484632');

    expect(requests.single.url, Uri.parse('https://api.twitch.tv/helix/chat/badges?broadcaster_id=22484632'));
    expect(badges.single.id, 'moderator/1');
    expect(badges.single.mipmap, ['https://x/1x', 'https://x/2x', 'https://x/4x']);
  });
}
