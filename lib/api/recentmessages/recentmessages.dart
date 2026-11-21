import '../api_client.dart';
import '../json_isolate.dart';

/// Chat history from before joining a channel, from recent-messages.robotty.de.
///
/// Settings → Chat history turns it off. [enabled] is asked before every request, so switching it takes effect with
/// the next fetch (opening a chat, joining, reconnecting); messages already shown stay.
class RecentMessages {
  /// Whether history may be fetched, e.g. `() => settings.chatHistory`.
  final bool Function() enabled;

  final ApiClient api;

  RecentMessages({required this.enabled, required this.api});

  static Uri uri(String channelLogin) =>
      Uri.parse('https://recent-messages.robotty.de/api/v2/recent-messages/$channelLogin');

  /// The recent messages of [channelLogin] as IRC lines, or null without any request while chat history is off.
  ///
  /// The status isn't checked, as it never was: an error answer that still has a `messages` list is used like any
  /// other, and one without throws while decoding.
  Future<List<String>?> channel(String channelLogin) async {
    if (!enabled()) return null;
    final response = await api.send('GET', uri(channelLogin));
    return ApiClient.decode(response, _messages, inIsolate: true);
  }

  // Static, so it can be sent to the isolate that decodes the response.
  static List<String> _messages(dynamic json) => List<String>.from((json as JsonMap)['messages'] as List<dynamic>);
}
