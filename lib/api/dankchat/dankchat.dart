import 'dart:convert';

import 'package:http/http.dart' as http;

import '../json_isolate.dart';

import 'dankchat_badge.dart';

class DankChat {
  static Future<List<DankChatBadge>> badges() async {
    final response = await http.get(Uri.parse('https://flxrs.com/api/badges'));
    final responseJson = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return [
      for (final badge in responseJson) DankChatBadge.fromJson(badge as JsonMap),
    ];
  }
}
