abstract class Provider {
  /// How long a request to a provider may take. Without a limit, one provider that stops answering (FrankerFaceZ did)
  /// kept the others' emotes and badges from showing, because they're loaded together.
  static const Duration timeout = Duration(seconds: 10);

  String get name;
  String? get description;
}
