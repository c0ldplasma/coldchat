abstract class ChatSource {
  /// How long a request to a source may take. Without a limit, one source that stops answering (FrankerFaceZ did)
  /// kept the others' emotes and badges from showing, because they're loaded together.
  static const Duration timeout = Duration(seconds: 10);

  String get name;
  String? get description;
}
