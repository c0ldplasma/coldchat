import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/glass.dart';
import '../components/modal.dart';
import '../components/pressable.dart';
import '../data/live/live_channels_cubit.dart';
import '../l10n/app_localizations.dart';
import '../sheets/channel.dart';
import '../sheets/coldchat.dart';
import '../sheets/whisper.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/channel/channel.dart';
import '../tmi/whispers/whisper_channel.dart';

/// The bottom of the home page: a floating glass capsule with the home tab, the channels and the whisper
/// conversations, and a round search button next to it that opens the channel search to add one, like iOS's tab bar
/// with its separate search button. (A "+" there would sit right below the composer's attachment "+".) Like iOS's tab bar, the selected tab sits
/// on a tinted pill that follows the finger while swiping between chats.
///
/// The keyboard and the emote panel cover it while they're up, and the composer sits on top of them; it doesn't move,
/// so nothing bounces when they go. Long-pressing a tab opens its sheet (the account sheet for the home tab).
class ChannelSwitcher extends StatelessWidget {
  final TabController controller;
  final List<Channel> channels;
  final List<WhisperChannel> whispers;
  final VoidCallback onAdd;

  const ChannelSwitcher({
    super.key,
    required this.controller,
    required this.channels,
    required this.whispers,
    required this.onAdd,
  });

  /// Height of the capsule and the "+" button.
  static const double height = 52.0;

  /// How far the switcher's capsule sits above the screen's bottom edge; the emote panel's section bar sits there
  /// too. iOS's floating tab bar reaches a little into the home indicator's area. Android's gesture bar is a hint to
  /// swipe from, which needs room of its own; and without either, keep off the screen's edge.
  static double bottomInset(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    if (safeBottom == 0.0) return 12.0;
    return Theme.of(context).platform == TargetPlatform.iOS ? safeBottom - 8.0 : safeBottom + 8.0;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final bottom = bottomInset(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, bottom),
      // The capsule is as wide as its tabs and scrolls once they fill the row; the search button stays at the end.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Glass(
              child: SizedBox(
                height: height,
                child: Padding(padding: const EdgeInsets.all(4.0), child: _tabs(context)),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Pressable(
            onTap: onAdd,
            semanticLabel: AppLocalizations.of(context).addChannel,
            haptic: true,
            child: Glass(
              shape: const CircleBorder(),
              child: SizedBox.square(
                dimension: height,
                child: Icon(Icons.search_rounded, size: 26.0, color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 14.0),
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: ShapeDecoration(shape: const StadiumBorder(), color: scheme.primary.withValues(alpha: 0.18)),
      dividerHeight: 0.0,
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurface,
      labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      // The pill is the feedback; a ripple on top of it would be Android's, not the capsule's.
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      onTap: (_) => unawaitedHaptic(HapticFeedback.selectionClick()),
      tabs: [
        _Tab(
          onLongPress: () => Modal.show(context: context, child: const ColdChatModal()),
          child: Semantics(
            label: AppLocalizations.of(context).home,
            child: const Icon(Icons.home_rounded, size: 24.0),
          ),
        ),
        for (final channel in channels)
          _Tab(
            onLongPress: () => Modal.show(
              context: context,
              child: ChannelModal(channel: channel),
            ),
            child: _ChannelLabel(channel: channel),
          ),
        for (final conversation in whispers)
          _Tab(
            onLongPress: () => Modal.show(
              context: context,
              child: WhisperModal(conversation: conversation),
            ),
            child: _WhisperLabel(conversation: conversation),
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onLongPress;

  const _Tab({required this.child, required this.onLongPress});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () {
      unawaitedHaptic(HapticFeedback.mediumImpact());
      unawaited(onLongPress());
    },
    child: SizedBox(
      height: ChannelSwitcher.height - 8.0,
      child: Center(child: child),
    ),
  );
}

/// A channel tab: its name without the `#`, after a red dot while the channel is live.
class _ChannelLabel extends StatelessWidget {
  final Channel channel;

  const _ChannelLabel({required this.channel});

  @override
  Widget build(BuildContext context) {
    final login = channel.name.replaceFirst('#', '').toLowerCase();
    return BlocSelector<LiveChannelsCubit, Set<String>, bool>(
      selector: (live) => live.contains(login),
      builder: (context, live) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            const DecoratedBox(
              decoration: BoxDecoration(color: ChatColors.live, shape: BoxShape.circle),
              child: SizedBox.square(dimension: 7.0),
            ),
            const SizedBox(width: 6.0),
          ],
          Text(channel.name.replaceFirst('#', '')),
        ],
      ),
    );
  }
}

/// A whisper tab: an envelope and the partner's name, both red while there are unread whispers.
class _WhisperLabel extends StatelessWidget {
  final WhisperChannel conversation;

  const _WhisperLabel({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unread;
    final color = unread ? ChatColors.unread : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(unread ? Icons.mark_email_unread_rounded : Icons.mail_outline_rounded, size: 18.0, color: color),
        const SizedBox(width: 6.0),
        Text(
          conversation.partnerDisplayName,
          style: unread ? const TextStyle(color: ChatColors.unread, fontWeight: FontWeight.w700) : null,
        ),
      ],
    );
  }
}
