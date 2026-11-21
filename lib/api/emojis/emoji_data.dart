import '../api_client.dart';
import '../json_isolate.dart';

/// The emoji list of iamcal/emoji-data on GitHub. No login.
class EmojiDataApi {
  final ApiClient _api;

  EmojiDataApi(this._api);

  /// The Twitter-style image of an emoji, by the `image` field of its entry.
  static String imageUrl(String image) =>
      'https://raw.githubusercontent.com/iamcal/emoji-data/master/img-twitter-72/$image';

  /// Every emoji entry, in the file's (codepoint) order.
  Future<List<JsonMap>> emojis() => _api.getJson(
    Uri.parse('https://raw.githubusercontent.com/iamcal/emoji-data/master/emoji.json'),
    (json) => (json as List<dynamic>).cast<JsonMap>(),
  );
}
