import 'dart:async';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/twitch/twitch.dart';
import '../api/twitch/twitch_profile.dart';
import '../data/twitch/token_data.dart';
import '../l10n/app_localizations.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/client/client.dart';
import '../tmi/moderation.dart';
import '../widgets/channel_view.dart';
import '../widgets/chat_view.dart';
import 'components/user_modal_header.dart';

class UserModal extends StatefulWidget {
  final String login;
  final Channel? channel;

  const UserModal({
    super.key,
    required this.login,
    this.channel,
  });

  @override
  State<UserModal> createState() => _UserModalState();
}

/// The scope Helix needs to ban, time out and unban. Logins from before the user card used it lack it.
const String _moderationScope = 'moderator:manage:banned_users';

class _UserModalState extends State<UserModal> {
  late final Future<TwitchProfile?> future;

  Channel? get channel => widget.channel;

  @override
  void initState() {
    super.initState();
    // Profiles come from Helix, which needs a login. Without one the panel
    // still shows the user's messages.
    final tokenData = (channel?.client ?? context.read<Client>()).apiTokenData;
    future = tokenData == null ? Future.value(null) : Twitch.profile(tokenData, widget.login).catchError((_) => null);
  }

  /// The token of the account that sends to [channel], or null while anonymous or disconnected.
  TokenData? get _moderatorTokenData {
    final tokenData = channel?.client.transmitter.twitchAccount?.tokenData;
    return tokenData?.accessToken == null ? null : tokenData;
  }

  /// Bans, times out or unbans through [action] and closes the card. A failure shows in a SnackBar, which is only
  /// visible once the sheet is gone.
  Future<void> _moderate(
    Future<void> Function(TokenData tokenData, String broadcasterId, String moderatorId) action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final tokenData = _moderatorTokenData;
    final broadcasterId = channel?.id;
    final moderatorId = tokenData?.userId;
    Navigator.of(context).pop();
    String? error;
    if (tokenData == null || broadcasterId == null || moderatorId == null) {
      error = l10n.moderationNeedsLogin;
    } else if (!tokenData.scopes.contains(_moderationScope)) {
      error = l10n.moderationNeedsScope;
    } else {
      try {
        await action(tokenData, broadcasterId, moderatorId);
      } on TwitchRequestException catch (e) {
        log('$e');
        error = l10n.moderationFailed(e.message);
      } catch (e) {
        log('$e');
        error = l10n.moderationFailed('$e');
      }
    }
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TwitchProfile?>(
    future: future,
    builder: (BuildContext context, AsyncSnapshot<TwitchProfile?> snapshot) {
      final shownChannel = channel;
      final canModerate = canModerateAs(shownChannel, _moderatorTokenData);
      final loading = snapshot.connectionState != ConnectionState.done;
      final profile = snapshot.data;
      return ListView(
        shrinkWrap: true,
        children: [
          if (loading || profile != null) UserModalHeader(profile: profile, name: widget.login),
          if (profile != null)
            _UserSafetyActions(client: channel?.client ?? context.read<Client>(), user: profile.user),
          // Moderation acts on a channel; a whisper conversation has none. Only the broadcaster and moderators can
          // ban, so the row is hidden for everyone else.
          if (canModerate && profile != null)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Row(
                children: [
                  Tooltip(
                    message: AppLocalizations.of(context).ban,
                    child: IconButton(
                      icon: const Icon(
                        Icons.block_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () => _moderate(
                        (tokenData, broadcasterId, moderatorId) => Twitch.ban(
                          tokenData,
                          broadcasterId: broadcasterId,
                          moderatorId: moderatorId,
                          userId: profile.user.id,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final time in {
                              '1s': const Duration(seconds: 1),
                              '30s': const Duration(seconds: 30),
                              '1m': const Duration(minutes: 1),
                              '5m': const Duration(minutes: 5),
                              '30m': const Duration(minutes: 30),
                              '1h': const Duration(hours: 1),
                              '1d': const Duration(days: 1),
                              '1w': const Duration(days: 7),
                            }.entries)
                              Tooltip(
                                message: AppLocalizations.of(context)
                                    .timeoutUserForDuration(time.value.toString().split('.').first),
                                child: TextButton(
                                  child: Text(time.key),
                                  onPressed: () => _moderate(
                                    (tokenData, broadcasterId, moderatorId) => Twitch.ban(
                                      tokenData,
                                      broadcasterId: broadcasterId,
                                      moderatorId: moderatorId,
                                      userId: profile.user.id,
                                      duration: time.value.inSeconds,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: AppLocalizations.of(context).unban,
                    child: IconButton(
                      icon: const Icon(
                        Icons.block_rounded,
                        color: Colors.green,
                      ),
                      onPressed: () => _moderate(
                        (tokenData, broadcasterId, moderatorId) => Twitch.unban(
                          tokenData,
                          broadcasterId: broadcasterId,
                          moderatorId: moderatorId,
                          userId: profile.user.id,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (channel != null)
            SizedBox(
              width: double.infinity,
              height: 350.0,
              child: ChatView(
                channel: channel!,
                filter: (message) {
                  if (message is! ChannelMessageChat) return false;
                  // TODO: change when proper user storage is done
                  return message.message.prefix?.split('!').first == widget.login;
                },
              ),
            ),
        ],
      );
    },
  );
}

/// Whisper, block and report. Block and report are what both stores require wherever users see each other's
/// messages. Blocking uses the account's Twitch block list, so it applies everywhere. Twitch has no API for
/// reports, so Report points to Twitch's own.
class _UserSafetyActions extends StatefulWidget {
  final Client client;
  final TwitchUser user;

  const _UserSafetyActions({required this.client, required this.user});

  @override
  State<_UserSafetyActions> createState() => _UserSafetyActionsState();
}

class _UserSafetyActionsState extends State<_UserSafetyActions> {
  bool busy = false;

  Future<void> toggleBlock() async {
    setState(() => busy = true);
    try {
      await widget.client.setBlocked(widget.user.id, !widget.client.isBlocked(widget.user.id));
    } catch (e) {
      log('$e');
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(AppLocalizations.of(context).blockFailed),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).close),
              ),
            ],
          ),
        );
      }
    }
    if (mounted) setState(() => busy = false);
  }

  /// Opens the conversation with this user as a tab and switches to it.
  Future<void> whisper() async {
    final navigator = Navigator.of(context);
    try {
      await widget.client.whispers.openAndFocus(widget.user.login);
      navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ChannelViewState.whisperErrorText(context, e))));
    }
  }

  Future<void> report() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context).reportUserTitle(widget.user.displayName)),
      content: Text(AppLocalizations.of(context).reportUserDescription(widget.user.displayName)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context).cancel)),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(
              launchUrl(Uri.parse('https://www.twitch.tv/${widget.user.login}'), mode: LaunchMode.externalApplication),
            );
          },
          child: Text(AppLocalizations.of(context).openOnTwitch),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ownUserId = widget.client.blockingUserId;
    final canBlock = ownUserId != null && ownUserId != widget.user.id;
    final blocked = widget.client.isBlocked(widget.user.id);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (canBlock)
          TextButton.icon(
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(AppLocalizations.of(context).whisper),
            onPressed: whisper,
          ),
        if (canBlock)
          TextButton.icon(
            icon: Icon(blocked ? Icons.person_outline_rounded : Icons.person_off_outlined),
            label: Text(blocked ? AppLocalizations.of(context).unblock : AppLocalizations.of(context).block),
            onPressed: busy ? null : toggleBlock,
          ),
        TextButton.icon(
          icon: const Icon(Icons.flag_outlined),
          label: Text(AppLocalizations.of(context).report),
          onPressed: report,
        ),
      ],
    );
  }
}
