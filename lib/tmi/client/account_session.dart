import 'dart:async';
import 'dart:developer';

import '../../api/twitch/helix_api.dart';
import '../../api/twitch/twitch.dart';
import '../../api/twitch/twitch_auth_api.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/twitch/token_data.dart';
import '../../data/twitch_account.dart';
import '../../irc/message.dart' as irc;
import '../connection/connection.dart';
import '../connection/connection_event.dart';
import '../connection/connection_state.dart';
import '../irc_log.dart';

/// The logged-in account: logs the [transmitter] in and out, checks with Twitch that the login is still valid and
/// locks it when it isn't, and keeps the account's block list and chat color.
class AccountSession implements AccountConnector {
  /// Sends as the active account; disconnected while logged out.
  final Connection transmitter;

  /// Helix, for the block list. Requests are sent as the connected account.
  final HelixApi helix;

  final TwitchAuthApi twitchAuth;

  /// Where a refreshed expiry of the active account is saved. Null in tests, then nothing is saved.
  final AccountRepository? accounts;

  /// Called when a token for API requests is there after browsing anonymously, e.g. to load the badges from Helix.
  final void Function() onApiAccessGained;

  /// Called when [connectAs] or [disconnect] switched the account (null when logged out), after [ownColor] was reset.
  final void Function(TwitchAccount? account) onAccountChanged;

  /// Called whenever the transmitter leaves every channel: it connects as another account or logs out.
  final void Function() onTransmitterLeftChannels;

  /// Called when the user [setBlocked] someone, so their messages are built again.
  final void Function(String userId) onBlockedChanged;

  // The account whose token is used for Twitch API requests such as badges.
  TwitchAccount? _apiAccount;

  /// The logged-in user's chat color, from GLOBALUSERSTATE, for the whispers they send.
  String? ownColor;

  late final Timer _validationTimer;

  /// Starts with [account] as the API account; [connectAs] logs the transmitter in.
  AccountSession({
    required this.transmitter,
    required this.helix,
    required this.twitchAuth,
    this.accounts,
    TwitchAccount? account,
    required this.onApiAccessGained,
    required this.onAccountChanged,
    required this.onTransmitterLeftChannels,
    required this.onBlockedChanged,
  }) : _apiAccount = account {
    // Twitch requires apps to validate a user token at startup and then hourly while running
    // (https://dev.twitch.tv/docs/authentication/validate-tokens/), so a login revoked on Twitch's side is noticed
    // even when the app stays open. Startup, every connect and every return to the foreground validate already.
    _validationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      final account = _apiAccount;
      if (account != null) unawaited(validateCredentials(account));
    });
  }

  /// Stops the hourly validation.
  void close() => _validationTimer.cancel();

  /// The token for Helix requests, or null while browsing anonymously.
  TokenData? get apiTokenData => _apiAccount?.tokenData.accessToken == null ? null : _apiAccount!.tokenData;

  /// The connected, logged-in account, which is the one whose Twitch block list hides messages.
  ConnectionConnected? get _blockingState {
    final state = transmitter.state;
    return state is ConnectionConnected && state.twitchAccount.tokenData.accessToken != null ? state : null;
  }

  /// The id of the account that can block users, or null while anonymous or disconnected.
  String? get blockingUserId => _blockingState?.twitchAccount.tokenData.userId;

  bool isBlocked(String userId) => _blockingState?.blockedUserIds.contains(userId) ?? false;

  /// Blocks or unblocks [userId] on Twitch and re-renders their messages in every channel.
  Future<void> setBlocked(String userId, bool blocked) async {
    final state = _blockingState;
    if (state == null) throw Exception('Not logged in');
    if (blocked) {
      await helix.forToken(state.twitchAccount.tokenData).blockUser(userId);
      if (!state.blockedUserIds.contains(userId)) state.blockedUserIds.add(userId);
    } else {
      await helix.forToken(state.twitchAccount.tokenData).unblockUser(userId);
      state.blockedUserIds.remove(userId);
    }
    onBlockedChanged(userId);
  }

  /// Fetches the (paginated, slow) block list of the account [connectedState] is logged in as, in the background, and
  /// fills it into the live state's mutable list. Nothing for an anonymous connection.
  void loadBlockedUsers(ConnectionConnected connectedState) {
    final tokenData = connectedState.twitchAccount.tokenData;
    if (tokenData.accessToken == null) return;
    unawaited(
      helix
          .forToken(tokenData)
          .blockedUsers()
          .then(connectedState.blockedUserIds.addAll)
          .catchError((Object e) => log('Couldn\'t get the blocked users: $e')),
    );
  }

  /// The own login that mentions highlight, or null while logged out.
  String? get ownLogin {
    final account = transmitter.twitchAccount;
    return account?.tokenData.accessToken == null ? null : account!.tokenData.login;
  }

  /// The app returned to the foreground: rejects an expired login, and validates any other one in the background.
  /// Returns whether the transmitter is worth probing, i.e. it's logged in and its login wasn't refused.
  bool checkLoginOnResume() {
    // A token can expire while the app sits in the background for days, so
    // check before probing: reconnecting with it is pointless and the socket
    // failure would be indistinguishable from a network hiccup.
    final account = transmitter.twitchAccount;
    if (account == null || account.tokenData.accessToken == null) return false;
    if (account.tokenData.isExpired) {
      _rejectCredentials(account);
      return false;
    }
    if (transmitter.credentialsRejected) return false;
    unawaited(validateCredentials(account));
    return true;
  }

  /// Twitch refuses a bad token with an untagged NOTICE whose text we have to
  /// match; there is no msg-id on these. Only ever sent with target `*` (i.e.
  /// before we are authenticated), which keeps this from matching channel chat.
  static bool isAuthFailureNotice(irc.Message event) {
    if (event.parameters.isEmpty || event.parameters.first != '*') return false;
    final text = event.parameters.length > 1 ? event.parameters.last.toLowerCase() : '';
    return text.contains('login authentication failed') ||
        text.contains('login unsuccessful') ||
        text.contains('improperly formatted auth');
  }

  /// Rejects the transmitter's login if [event], received on [connection], is Twitch refusing it. Returns whether
  /// [event] was such a refusal (on any connection), so it isn't handled as a channel NOTICE.
  bool handleAuthFailureNotice(Connection connection, irc.Message event) {
    if (!isAuthFailureNotice(event)) return false;
    // Only the transmitter logs in; the receiver has no token to refuse.
    final account = connection.twitchAccount;
    if (connection == transmitter && account != null) _rejectCredentials(account);
    return true;
  }

  /// Locks the transmitter until a new login, because Twitch refused [twitchAccount]'s token. The anonymous receiver
  /// has no token and keeps reading. Ignored when [twitchAccount] isn't the active account anymore (e.g. a check
  /// that was still running while switching accounts), so it can't lock out the account that is active now.
  void _rejectCredentials(TwitchAccount twitchAccount) {
    final active = _apiAccount;
    if (active == null || active.tokenData.hash != twitchAccount.tokenData.hash) return;
    ircLog('transmitter: login of ${twitchAccount.tokenData.login} rejected');
    transmitter.add(ConnectionCredentialsRejected(twitchAccount));
  }

  /// Ask Twitch whether the stored token is still good, and keep [TokenData]
  /// honest about it. On a 401 the login is dead — reject it so the UI can say
  /// so instead of letting the reconnect loop churn silently. Network failures
  /// are ignored: being offline is not proof the token expired.
  Future<void> validateCredentials(TwitchAccount twitchAccount) async {
    final accessToken = twitchAccount.tokenData.accessToken;
    if (accessToken == null) return; // anonymous
    if (twitchAccount.tokenData.isExpired) {
      _rejectCredentials(twitchAccount);
      return;
    }

    try {
      final fresh = await twitchAuth.validateToken(accessToken);
      // The stored expiresAt is a snapshot from login time and is never touched
      // afterwards; refresh it so the account modal and the local expiry check
      // reflect reality.
      twitchAccount.tokenData.expiresAt = fresh.expiresAt;
      twitchAccount.tokenData.scopes = fresh.scopes;
      try {
        await accounts?.update(twitchAccount);
      } catch (_) {
        // Not attached to a box (e.g. constructed in-memory) — nothing to persist.
      }
      if (twitchAccount.tokenData.isExpired) _rejectCredentials(twitchAccount);
    } on TwitchTokenInvalidException {
      _rejectCredentials(twitchAccount);
    } catch (e) {
      log('Couldn\'t validate the Twitch token: $e');
    }
  }

  @override
  Future<void> connectAs(TwitchAccount twitchAccount) async {
    // Don't even open the socket with a token we already know is dead: the
    // handshake would fail with no feedback.
    if (twitchAccount.tokenData.accessToken != null && twitchAccount.tokenData.isExpired) {
      _apiAccount = twitchAccount;
      onTransmitterLeftChannels();
      _rejectCredentials(twitchAccount);
      return;
    }

    // Without a token the Twitch badges came from ivr.fi; a first login after
    // browsing anonymously loads them from Helix instead.
    final gainedApiAccess = _apiAccount?.tokenData.accessToken == null && twitchAccount.tokenData.accessToken != null;
    _apiAccount = twitchAccount;
    if (gainedApiAccess) onApiAccessGained();
    ircLog('transmitter: switching to ${twitchAccount.tokenData.login}');

    ownColor = null;
    onAccountChanged(twitchAccount);

    // Only the transmitter changes account. The receiver keeps reading, so the chat stays live and nothing is parted,
    // rejoined or fetched again; the composer waits until the transmitter has joined the channel (Channel.canSend).
    onTransmitterLeftChannels();
    transmitter.add(ConnectionConnect(twitchAccount));
    // Confirm with Twitch in the background — the local expiry check only
    // catches tokens we know about; a manually revoked one still needs the API.
    unawaited(validateCredentials(twitchAccount));
  }

  /// Logs out: closes the transmitter until [connectAs] is called again. The anonymous receiver keeps reading the
  /// chat.
  @override
  void disconnect() {
    ircLog('transmitter: logging out');
    _apiAccount = null;
    ownColor = null;
    onAccountChanged(null);
    onTransmitterLeftChannels();
    transmitter.add(ConnectionDisconnect());
  }
}
