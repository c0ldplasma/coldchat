import 'package:http/http.dart' as http;

import '../json_isolate.dart';

/// Chat history from before joining a channel, from recent-messages.robotty.de.
///
/// Settings → Chat history turns it off. [enabled] is asked before every request, so switching it takes effect with
/// the next fetch (opening a chat, joining, reconnecting); messages already shown stay.
class RecentMessages {
  /// Whether history may be fetched, e.g. `() => settings.chatHistory`.
  final bool Function() enabled;

  /// For tests; without one every request goes through a client of its own that is closed afterwards.
  final http.Client? client;

  RecentMessages({required this.enabled, this.client});

  static Uri uri(String channelLogin) =>
      Uri.parse('https://recent-messages.robotty.de/api/v2/recent-messages/$channelLogin');

  /// The recent messages of [channelLogin] as IRC lines, or null without any request while chat history is off.
  Future<List<String>?> channel(String channelLogin) async {
    if (!enabled()) return null;
    final httpClient = client ?? http.Client();
    final http.Response response;
    try {
      response = await httpClient.get(uri(channelLogin));
    } finally {
      if (client == null) httpClient.close();
    }
    return decodeJsonInIsolate(
      response.bodyBytes,
      (json) => List<String>.from((json as JsonMap)['messages'] as List<dynamic>),
    );
  }
}
