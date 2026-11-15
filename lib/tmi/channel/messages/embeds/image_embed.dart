class ImageEmbed {
  final String url;

  /// Set when the user tapped "Show image" on this link, so it stays visible when the message is rebuilt.
  bool revealed = false;

  ImageEmbed({
    required this.url,
  });
}
