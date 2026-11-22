import 'dart:convert';

import 'package:coldchat/api/seventv/seventv.dart';
import 'package:coldchat/sources/seventv_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../api/fake_api.dart';

Map<String, dynamic> _file(String name, String format) => {
  'name': name,
  'static_name': name.replaceFirst('.', '_static.'),
  'width': 128,
  'height': 128,
  'frame_count': 1,
  'size': 1000,
  'format': format,
};

Map<String, dynamic> _emote(String id, String name, List<Map<String, dynamic>> files) => {
  'id': id,
  'name': name,
  'flags': 0,
  'timestamp': 0,
  'data': {
    'id': id,
    'name': name,
    'flags': 0,
    'lifecycle': 3,
    'state': ['LISTED'],
    'listed': true,
    'animated': true,
    'owner': null,
    'host': {'url': '//cdn.7tv.app/emote/$id', 'files': files},
  },
};

void main() {
  SevenTvSource source(Object body) =>
      SevenTvSource(SevenTvApi(fakeApi((request) async => http.Response(jsonEncode(body), 200))));

  // 7TV lists every size in each format, in this order.
  final allFormats = [
    for (final format in ['WEBP', 'AVIF', 'GIF'])
      for (final size in ['1x', '2x', '3x', '4x']) _file('$size.${format.toLowerCase()}', format),
  ];

  test('uses the WebP files, so the largest size is 4x.webp', () async {
    final emotes = await source({
      'emotes': [_emote('01A', 'RainTime', allFormats)],
    }).globalEmotes();

    expect(emotes.single.mipmap, [
      'https://cdn.7tv.app/emote/01A/1x.webp',
      'https://cdn.7tv.app/emote/01A/2x.webp',
      'https://cdn.7tv.app/emote/01A/3x.webp',
      'https://cdn.7tv.app/emote/01A/4x.webp',
    ]);
  });

  test('channel emotes use the WebP files too', () async {
    final emotes = await source({
      'emote_set': {
        'emotes': [_emote('01B', 'peepoHey', allFormats)],
      },
    }).channelEmotes('1');

    expect(emotes.single.mipmap.last, 'https://cdn.7tv.app/emote/01B/4x.webp');
  });

  test('falls back to the other formats except AVIF when an emote has no WebP files', () async {
    final emotes = await source({
      'emotes': [
        _emote('01C', 'OldEmote', [
          _file('1x.avif', 'AVIF'),
          _file('4x.avif', 'AVIF'),
          _file('1x.png', 'PNG'),
          _file('4x.png', 'PNG'),
        ]),
      ],
    }).globalEmotes();

    expect(emotes.single.mipmap, [
      'https://cdn.7tv.app/emote/01C/1x.png',
      'https://cdn.7tv.app/emote/01C/4x.png',
    ]);
  });
}
