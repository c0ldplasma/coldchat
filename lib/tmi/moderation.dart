import 'dart:developer';

import '../api/twitch/helix_api.dart';
import '../api/twitch/twitch.dart';
import '../data/twitch/token_data.dart';
import 'channel/channel.dart';
import 'whispers/whisper_channel.dart';

/// Whether the account of [tokenData] gets the moderation actions in [channel] (deleting messages, banning and
/// timing out): it's logged in (an anonymous account has no access token), [channel] is a real channel and not a
/// whisper conversation, and the account is its broadcaster or a moderator there ([Channel.canModerate]).
bool canModerateAs(Channel? channel, TokenData? tokenData) =>
    channel != null &&
    channel is! WhisperChannel &&
    tokenData?.accessToken != null &&
    channel.canModerate(tokenData!.userId);

/// Whether the `badges` tag of a USERSTATE makes the own user a moderator of that channel: it has the moderator or
/// the broadcaster badge.
bool hasModeratorBadge(String? badges) =>
    (badges ?? '').split(',').any((badge) => badge.startsWith('moderator/') || badge.startsWith('broadcaster/'));

/// The scope Helix needs to ban, time out and unban. Logins from before the user card used it lack it.
const String moderationScope = 'moderator:manage:banned_users';

/// Why an account can't ban, time out or unban; both are fixed by signing in (again).
enum ModerationBlocker { needsLogin, needsScope }

/// What keeps [tokenData] from moderating [broadcasterId]'s channel, or null when it can try. Failures of the
/// request itself are not decided here: they show without a "Sign in" button.
ModerationBlocker? moderationBlocker(TokenData? tokenData, {required String? broadcasterId}) {
  if (tokenData == null || broadcasterId == null || tokenData.userId == null) return ModerationBlocker.needsLogin;
  if (!tokenData.scopes.contains(moderationScope)) return ModerationBlocker.needsScope;
  return null;
}

/// Whether [tokenData] may delete messages. Logins from before ColdChat requested the scope can't until they sign
/// in again.
bool canDeleteMessagesWith(TokenData? tokenData) =>
    tokenData != null && tokenData.scopes.contains(HelixApi.deleteChatMessageScope);

/// Whether signing in again fixes a failed delete: Twitch answers 401 when the token lacks the scope.
bool deleteFailureNeedsSignIn(Object error) => error is TwitchRequestException && error.statusCode == 401;

/// What a ban, timeout, unban or delete does to a user or message.
sealed class ModerationAction {
  const ModerationAction();
}

/// Bans [userId] for good.
final class ModerationBan extends ModerationAction {
  final String userId;

  const ModerationBan(this.userId);
}

/// Times [userId] out for [duration].
final class ModerationTimeout extends ModerationAction {
  final String userId;
  final Duration duration;

  const ModerationTimeout(this.userId, this.duration);
}

/// Lifts a ban or timeout of [userId].
final class ModerationUnban extends ModerationAction {
  final String userId;

  const ModerationUnban(this.userId);
}

/// Why a moderation action didn't happen. The UI turns it into a text; [needsSignIn] says whether signing in
/// (again) fixes it.
sealed class ModerationFailure {
  const ModerationFailure();

  bool get needsSignIn;
}

/// The account isn't logged in, or the channel or the account's user id is unknown.
final class ModerationNeedsLogin extends ModerationFailure {
  const ModerationNeedsLogin();

  @override
  bool get needsSignIn => true;

  @override
  bool operator ==(Object other) => other is ModerationNeedsLogin;

  @override
  int get hashCode => (ModerationNeedsLogin).hashCode;
}

/// The login lacks the scope the action needs.
final class ModerationNeedsScope extends ModerationFailure {
  const ModerationNeedsScope();

  @override
  bool get needsSignIn => true;

  @override
  bool operator ==(Object other) => other is ModerationNeedsScope;

  @override
  int get hashCode => (ModerationNeedsScope).hashCode;
}

/// Twitch refused, or the request failed: [reason] is Twitch's message or the error.
final class ModerationRequestFailed extends ModerationFailure {
  final String reason;

  const ModerationRequestFailed(this.reason);

  @override
  bool get needsSignIn => false;

  @override
  bool operator ==(Object other) => other is ModerationRequestFailed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Bans, times out or unbans in the channel [broadcasterId] as the account of [tokenData]. Returns null once it's
/// done, otherwise why not. [helix] is sent the request as [tokenData].
Future<ModerationFailure?> moderateAs(
  TokenData? tokenData,
  ModerationAction action, {
  required String? broadcasterId,
  required HelixApi helix,
}) async {
  switch (moderationBlocker(tokenData, broadcasterId: broadcasterId)) {
    case ModerationBlocker.needsLogin:
      return const ModerationNeedsLogin();
    case ModerationBlocker.needsScope:
      return const ModerationNeedsScope();
    case null:
  }
  // moderationBlocker made sure all three are there.
  final asAccount = helix.forToken(tokenData!);
  final moderatorId = tokenData.userId!;
  try {
    switch (action) {
      case ModerationBan(:final userId):
        await asAccount.ban(broadcasterId: broadcasterId!, moderatorId: moderatorId, userId: userId);
      case ModerationTimeout(:final userId, :final duration):
        await asAccount.ban(
          broadcasterId: broadcasterId!,
          moderatorId: moderatorId,
          userId: userId,
          duration: duration.inSeconds,
        );
      case ModerationUnban(:final userId):
        await asAccount.unban(broadcasterId: broadcasterId!, moderatorId: moderatorId, userId: userId);
    }
    return null;
  } on TwitchRequestException catch (e) {
    log('$e');
    return ModerationRequestFailed(e.message);
  } catch (e) {
    log('$e');
    return ModerationRequestFailed('$e');
  }
}

/// Deletes the message [messageId] in the channel [broadcasterId] as the account of [tokenData]. Returns null once
/// it's deleted, otherwise why not. [helix] is sent the request as [tokenData].
Future<ModerationFailure?> deleteMessageAs(
  TokenData? tokenData, {
  required String? broadcasterId,
  required String messageId,
  required HelixApi helix,
}) async {
  if (tokenData == null || !canDeleteMessagesWith(tokenData)) return const ModerationNeedsScope();
  try {
    await helix
        .forToken(tokenData)
        .deleteChatMessage(broadcasterId: broadcasterId!, moderatorId: tokenData.userId!, messageId: messageId);
    return null;
  } on TwitchRequestException catch (e) {
    return deleteFailureNeedsSignIn(e) ? const ModerationNeedsScope() : ModerationRequestFailed(e.message);
  } catch (e) {
    return ModerationRequestFailed('$e');
  }
}

/// Moderation in a channel as the account that sends to it.
extension ChannelModeration on Channel {
  /// The token of the account that sends to this channel, or null while anonymous or disconnected.
  TokenData? get moderatorTokenData {
    final tokenData = client.transmitter.twitchAccount?.tokenData;
    return tokenData?.accessToken == null ? null : tokenData;
  }

  /// Whether the sending account gets the moderation actions here, see [canModerateAs].
  bool get canModerateHere => canModerateAs(this, moderatorTokenData);

  /// Bans, times out or unbans as the sending account, see [moderateAs].
  Future<ModerationFailure?> moderate(ModerationAction action) =>
      moderateAs(moderatorTokenData, action, broadcasterId: id, helix: client.helix);

  /// Deletes the message [messageId] as the sending account, see [deleteMessageAs].
  Future<ModerationFailure?> deleteMessage(String messageId) => deleteMessageAs(
    client.transmitter.twitchAccount?.tokenData,
    broadcasterId: id,
    messageId: messageId,
    helix: client.helix,
  );
}
