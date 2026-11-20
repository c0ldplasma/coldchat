/// An error raised by the chat connection code.
///
/// [toString] is just the message, so logs (e.g. the connection logs page)
/// show the same text a plain string did.
class TmiException implements Exception {
  final String message;

  const TmiException(this.message);

  @override
  String toString() => message;
}
