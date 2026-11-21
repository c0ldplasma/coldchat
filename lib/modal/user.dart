import 'dart:async';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/twitch/twitch_profile.dart';
import '../l10n/app_localizations.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/client/client.dart';
import '../tmi/client/client_lookups.dart';
import '../tmi/moderation.dart';
import '../tools/duration_text.dart';
import '../widgets/chat_view.dart';
import 'components/user_modal_header.dart';
import 'login_flow.dart';
import 'whisper_errors.dart';

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

/// What to tell the user when a ban, timeout or unban failed with [failure].
String moderationFailureText(AppLocalizations l10n, ModerationFailure failure) => switch (failure) {
  ModerationNeedsLogin() => l10n.moderationNeedsLogin,
  ModerationNeedsScope() => l10n.moderationNeedsScope,
  ModerationRequestFailed(:final reason) => l10n.moderationFailed(reason),
};

class _UserModalState extends State<UserModal> {
  late final Future<TwitchProfile?> future;

  Channel? get channel => widget.channel;

  @override
  void initState() {
    super.initState();
    // Profiles come from Helix, which needs a login. Without one the panel
    // still shows the user's messages.
    future = (channel?.client ?? context.read<Client>()).profileOf(widget.login);
  }

  /// Bans, times out or unbans and closes the card. A failure shows in a SnackBar, which is only visible once the
  /// sheet is gone.
  Future<void> _moderate(ModerationAction action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    final failure = await (channel?.moderate(action) ?? Future.value(const ModerationNeedsLogin()));
    if (failure == null) return;
    final text = moderationFailureText(l10n, failure);
    if (failure.needsSignIn) {
      showSignInSnackBar(messenger, navigator, text);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TwitchProfile?>(
    future: future,
    builder: (BuildContext context, AsyncSnapshot<TwitchProfile?> snapshot) {
      final shownChannel = channel;
      final canModerate = shownChannel?.canModerateHere ?? false;
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
                      onPressed: () => _moderate(ModerationBan(profile.user.id)),
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
                                    .timeoutUserForDuration(shortDuration(time.value, AppLocalizations.of(context))),
                                child: TextButton(
                                  child: Text(time.key),
                                  onPressed: () => _moderate(ModerationTimeout(profile.user.id, time.value)),
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
                      onPressed: () => _moderate(ModerationUnban(profile.user.id)),
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.client.whispers.openAndFocus(widget.user.login);
      navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      showWhisperError(messenger, navigator, e);
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
