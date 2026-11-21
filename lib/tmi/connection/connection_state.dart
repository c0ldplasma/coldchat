import 'package:equatable/equatable.dart';

import '../../data/twitch_account.dart';

abstract class ConnectionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConnectionDisconnected extends ConnectionState {}

abstract class ConnectionStateWithCredentials extends ConnectionState {
  final TwitchAccount twitchAccount;

  ConnectionStateWithCredentials(this.twitchAccount);

  @override
  List<Object?> get props => [twitchAccount, ...super.props];
}

class ConnectionConnecting extends ConnectionStateWithCredentials {
  ConnectionConnecting(super.credentials);
}

class ConnectionConnected extends ConnectionStateWithCredentials {
  // The list itself is mutable so the (paginated, potentially slow)
  // blocked-user fetch can fill it in the background after the connected
  // state is emitted, without blocking channel joins on it. Not part of
  // Equatable props.
  final List<String> blockedUserIds;

  /// The nick Twitch registered the connection with (from its 001), e.g. the random `justinfan` nick of an
  /// anonymous connection. Twitch echoes JOINs with it.
  final String nick;

  ConnectionConnected(
    super.credentials, {
    List<String>? blockedUserIds,
    String? nick,
  }) : blockedUserIds = blockedUserIds ?? [],
       nick = (nick ?? credentials.tokenData.login).toLowerCase();
}

class ConnectionReconnecting extends ConnectionStateWithCredentials {
  ConnectionReconnecting(super.credentials);
}

class ConnectionBanned extends ConnectionStateWithCredentials {
  ConnectionBanned(super.credentials);
}

class ConnectionInvalidCredentials extends ConnectionStateWithCredentials {
  ConnectionInvalidCredentials(super.credentials);
}
