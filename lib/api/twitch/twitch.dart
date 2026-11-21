/// A request Twitch refused, with the reason Twitch gave. Its [message] is meant to be shown to the user.
class TwitchRequestException implements Exception {
  final int statusCode;
  final String message;

  TwitchRequestException(this.statusCode, this.message);

  @override
  String toString() => 'TwitchRequestException($statusCode): $message';
}

/// A request Twitch refused with 401.
///
/// From `/oauth2/validate` it means the access token is dead and the user has to sign in again, as distinct from a
/// generic failure ("the network is down, try later"). From Helix it can also mean that the token lacks a scope,
/// so it is a [TwitchRequestException] too and shows Twitch's reason wherever those are shown.
class TwitchTokenInvalidException extends TwitchRequestException {
  TwitchTokenInvalidException([String message = 'The access token is no longer valid']) : super(401, message);

  @override
  String toString() => 'TwitchTokenInvalidException: $message';
}
