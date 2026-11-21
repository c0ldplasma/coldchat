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
