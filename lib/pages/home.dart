import 'dart:async';

import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/modal/channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../components/dark_bar.dart';
import '../components/modal.dart';
import '../modal/coldchat.dart';
import '../modal/whisper.dart';
import '../tmi/channel/channel.dart';
import '../tmi/client/client.dart';
import '../tmi/client/client_channels.dart';
import '../tmi/connection/connection.dart';
import '../tmi/connection/connection_state.dart' as tmi;
import '../tmi/whispers/whisper_channel.dart';
import '../tmi/whispers/whispers.dart';
import '../widgets/channel_view.dart';
import '../widgets/home_tab.dart';
import '../widgets/login_expired_banner.dart';

/// Lets descendants (the search/stream tiles in [HomeTab]) ask the home page to
/// switch to a channel tab after joining it. Provided via [Provider] from
/// [_HomePageState] so it can drive the manually-managed [TabController].
class HomeTabSwitcher {
  final void Function(String channelName) open;
  const HomeTabSwitcher(this.open);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const String _lastChannelKey = 'lastChannel';

  TabController? _tabController;
  int _lastLength = -1;
  // Always reflects the tab list (channels, then whisper conversations) from
  // the latest build so the tab listener doesn't capture a stale list (the
  // controller is only rebuilt when the length changes, but channels can be
  // swapped/reordered at the same count). A whisper tab's name is `@login`.
  List<Channel> _channels = const [];

  final List<StreamSubscription> _whisperSubs = [];

  @override
  void initState() {
    super.initState();
    final whispers = context.read<Client>().whispers;
    _whisperSubs.addAll([
      whispers.focusRequests.listen((conversation) => _openChannel(conversation.name)),
      whispers.received.listen(_onWhisperReceived),
    ]);
  }

  // The tab turns red; the snackbar also points to it when the tab is
  // scrolled out of view.
  void _onWhisperReceived(WhisperChannel conversation) {
    if (!mounted || context.read<Client>().whispers.active == conversation) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.whisperFrom(conversation.partnerDisplayName)),
      action: SnackBarAction(label: l10n.openWhisper, onPressed: () => _openChannel(conversation.name)),
    ));
  }

  // Tells the whispers which conversation is on screen, so it isn't marked
  // unread, and clears the red mark of the one just opened.
  void _updateActiveWhisper() {
    final controller = _tabController;
    if (controller == null) return;
    final whispers = context.read<Client>().whispers;
    final index = controller.index;
    final tab = index > 0 && index - 1 < _channels.length ? _channels[index - 1] : null;
    whispers.active = tab is WhisperChannel ? tab : null;
    if (tab is WhisperChannel) whispers.markRead(tab);
  }

  int _initialIndexFor(List<Channel> channels) {
    final lastName = Hive.box('Settings').get(_lastChannelKey);
    if (lastName is! String || lastName.isEmpty) return 0;
    final idx = channels.indexWhere((c) => c.name == lastName);
    return idx >= 0 ? idx + 1 : 0;
  }

  late final HomeTabSwitcher _switcher = HomeTabSwitcher(_openChannel);

  // Switch to the given channel's tab. Persist it as the last channel first so
  // that if the channel was just added (tab count grows -> controller is
  // recreated with initialIndex), the recreated controller already lands here;
  // for an already-joined channel the post-frame animateTo moves to it.
  void _openChannel(String channelName) {
    Hive.box('Settings').put(_lastChannelKey, channelName);
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      WidgetsBinding.instance.scheduleFrameCallback((_) {
        if (!mounted) return;
        final controller = _tabController;
        if (controller == null) return;
        final idx = _channels.indexWhere((c) => c.name == channelName);
        if (idx < 0) return;
        final target = (idx + 1).clamp(0, controller.length - 1);
        if (controller.index != target) controller.animateTo(target);
      });
    });
  }

  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    final index = controller.index;
    final name = index == 0
        ? ''
        : (index - 1 < _channels.length ? _channels[index - 1].name : '');
    Hive.box('Settings').put(_lastChannelKey, name);
    _updateActiveWhisper();
  }

  TabController _ensureController(List<Channel> channels) {
    _channels = channels;
    final desiredLength = 1 + channels.length;
    if (_tabController == null || _lastLength != desiredLength) {
      _tabController?.dispose();
      _tabController = TabController(
        length: desiredLength,
        vsync: this,
        initialIndex: _initialIndexFor(channels).clamp(0, desiredLength - 1),
      );
      _tabController!.addListener(_onTabChanged);
      _lastLength = desiredLength;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateActiveWhisper();
      });
    }
    return _tabController!;
  }

  @override
  void dispose() {
    for (final sub in _whisperSubs) {
      sub.cancel();
    }
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ClientChannels, List<Channel>>(
        bloc: context.read<Client>().channels,
        builder: (context, channels) => BlocBuilder<Whispers, List<WhisperChannel>>(
          bloc: context.read<Client>().whispers,
          builder: (context, whispers) {
            final state = [...channels, ...whispers];
            final tabController = _ensureController(state);
            return Provider<HomeTabSwitcher>.value(
              value: _switcher,
              child: Scaffold(
                extendBody: true,
                extendBodyBehindAppBar: true,
                bottomNavigationBar: DarkBar(
                  child: Builder(builder: (context) {
                    final fg = DarkBar.foregroundColor(context);
                    return TabBar(
                      controller: tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: fg,
                      unselectedLabelColor: fg.withValues(alpha: 0.6),
                      indicatorColor: fg,
                      dividerColor: Colors.transparent,
                      tabs: [
                        GestureDetector(
                          onLongPress: () {
                            Modal.show(
                              context: context,
                              child: const ColdChatModal(),
                            );
                          },
                          child: const SizedBox(
                            height: 48.0,
                            child: Icon(Icons.home_outlined),
                          ),
                        ),
                        for (final channel in channels)
                          GestureDetector(
                            onLongPress: () {
                              Modal.show(
                                context: context,
                                child: ChannelModal(channel: channel),
                              );
                            },
                            child: SizedBox(
                              height: 48.0,
                              child: Center(child: Text(channel.name)),
                            ),
                          ),
                        for (final conversation in whispers)
                          GestureDetector(
                            onLongPress: () {
                              Modal.show(
                                context: context,
                                child: WhisperModal(conversation: conversation),
                              );
                            },
                            child: SizedBox(
                              height: 48.0,
                              child: Center(child: _WhisperTabLabel(conversation: conversation)),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
                body: BlocBuilder<Connection, tmi.ConnectionState>(
                  bloc: context.read<Client>().receiver,
                  builder: (context, connectionState) {
                    // The banner claims the status-bar inset itself, so drop the
                    // top inset for everything below it — otherwise the home
                    // tab's large app bar and the chat view would each add it a
                    // second time and leave a gap under the banner.
                    final loginExpired = connectionState is tmi.ConnectionInvalidCredentials;
                    return Column(
                      children: [
                        const LoginExpiredBanner(),
                        Expanded(
                          child: MediaQuery.removePadding(
                            context: context,
                            removeTop: loginExpired,
                            child: TabBarView(
                              controller: tabController,
                              children: [
                                const HomeTab(),
                                for (final channel in state)
                                  ChannelView(
                                    key: ObjectKey(channel),
                                    channel: channel,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
}

/// A whisper tab: the partner's name, on red while there are unread whispers.
class _WhisperTabLabel extends StatelessWidget {
  final WhisperChannel conversation;

  const _WhisperTabLabel({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unread = conversation.unread;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mail_outline_rounded, size: 16.0, color: unread ? colors.onError : null),
        const SizedBox(width: 4.0),
        Text(
          conversation.partnerDisplayName,
          style: unread ? TextStyle(color: colors.onError, fontWeight: FontWeight.bold) : null,
        ),
      ],
    );
    if (!unread) return label;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.error, borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: label,
      ),
    );
  }
}
