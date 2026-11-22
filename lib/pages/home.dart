import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../components/bottom_bar.dart';
import '../components/modal.dart';
import '../data/home/home_streams_cubit.dart';
import '../data/home/start_screen_cubit.dart';
import '../data/live/live_channels_cubit.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/channel_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../sheets/channel.dart';
import '../sheets/coldchat.dart';
import '../sheets/whisper.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/channel/channel.dart';
import '../tmi/client/client.dart';
import '../tmi/client/client_channels.dart';
import '../tmi/client/client_lookups.dart';
import '../tmi/connection/connection.dart';
import '../tmi/connection/connection_state.dart' as tmi;
import '../tmi/whispers/whisper_channel.dart';
import '../tmi/whispers/whispers.dart';
import '../widgets/channel_view.dart';
import '../widgets/home_tab.dart';
import '../widgets/logged_out_start.dart';
import '../widgets/login_expired_banner.dart';

/// Lets descendants (the search/stream tiles in [HomeTab]) ask the home page to
/// switch to a channel tab after joining it. Provided via [Provider] from
/// [_HomePageState] so it can drive the manually-managed [TabController].
class HomeTabSwitcher {
  final void Function(String channelName) open;

  /// Set by the "+" in the tab bar for [HomeTab], which focuses its channel search.
  final ChannelSearchRequest searchRequest;

  const HomeTabSwitcher(this.open, this.searchRequest);
}

/// A request to focus the channel search on the home tab. It stays pending until [HomeTab] takes it, because the
/// home tab may not be built yet while the tab view is still animating towards it.
class ChannelSearchRequest extends ChangeNotifier {
  bool _pending = false;

  void request() {
    _pending = true;
    notifyListeners();
  }

  /// Whether a request was pending; clears it.
  bool take() {
    final pending = _pending;
    _pending = false;
    return pending;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _lastLength = -1;
  // Always reflects the tab list (channels, then whisper conversations) from
  // the latest build so the tab listener doesn't capture a stale list (the
  // controller is only rebuilt when the length changes, but channels can be
  // swapped/reordered at the same count). A whisper tab's name is `@login`.
  List<Channel> _channels = const [];

  final List<StreamSubscription<dynamic>> _whisperSubs = [];

  @override
  void initState() {
    super.initState();
    final whispers = context.read<Client>().whispers;
    _whisperSubs.addAll([
      whispers.focusRequests.listen((conversation) => _openChannel(conversation.name)),
      whispers.received.listen(_onWhisperReceived),
      // Reply or Mention in a message sheet: show the composer it went to. A no-op for the tab already shown.
      context.read<Client>().channelFocusRequests.listen(_openChannel),
    ]);
  }

  // The tab turns red; the snackbar also points to it when the tab is
  // scrolled out of view.
  void _onWhisperReceived(WhisperChannel conversation) {
    if (!mounted || context.read<Client>().whispers.active == conversation) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.whisperFrom(conversation.partnerDisplayName)),
        action: SnackBarAction(label: l10n.openWhisper, onPressed: () => _openChannel(conversation.name)),
      ),
    );
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
    final lastName = context.read<ChannelRepository>().lastChannel;
    if (lastName == null || lastName.isEmpty) return 0;
    final idx = channels.indexWhere((c) => c.name == lastName);
    return idx >= 0 ? idx + 1 : 0;
  }

  final ChannelSearchRequest _searchRequest = ChannelSearchRequest();
  late final HomeTabSwitcher _switcher = HomeTabSwitcher(_openChannel, _searchRequest);

  // The "+" in the tab bar: back to the home tab, straight into the channel search.
  void _openChannelSearch() {
    _tabController?.animateTo(0);
    _searchRequest.request();
  }

  // Switch to the given channel's tab. Persist it as the last channel first so
  // that if the channel was just added (tab count grows -> controller is
  // recreated with initialIndex), the recreated controller already lands here;
  // for an already-joined channel the post-frame animateTo moves to it.
  void _openChannel(String channelName) {
    unawaited(context.read<ChannelRepository>().setLastChannel(channelName));
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
    final name = index == 0 ? '' : (index - 1 < _channels.length ? _channels[index - 1].name : '');
    unawaited(context.read<ChannelRepository>().setLastChannel(name));
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
      unawaited(sub.cancel());
    }
    _tabController?.dispose();
    _searchRequest.dispose();
    super.dispose();
  }

  // A fresh install first shows only the start screen, without the tab bar, until the user logs in or continues
  // without logging in.
  @override
  Widget build(BuildContext context) => BlocProvider<StartScreenCubit>(
    create: (context) {
      final settings = context.read<SettingsRepository>();
      final accounts = context.read<AccountRepository>();
      return StartScreenCubit(
        isDone: () => settings.startScreenDone,
        markDone: settings.finishStartScreen,
        hasAccount: () => accounts.accounts.isNotEmpty,
        changes: Listenable.merge([settings.startScreenChanges, accounts.changes]),
      );
    },
    child: BlocBuilder<StartScreenCubit, bool>(
      builder: (context, startScreen) => startScreen ? const Scaffold(body: LoggedOutStart()) : _buildHome(context),
    ),
  );

  // Above the tab view, which disposes the home tab on every tab switch, so its stream lists survive switching.
  Widget _buildHome(BuildContext context) => BlocProvider<HomeStreamsCubit>(
    create: (context) {
      final accounts = context.read<AccountRepository>();
      final client = context.read<Client>();
      return HomeStreamsCubit(
        helix: () => client.helixAsActive(accounts),
        accountChanges: accounts.activeChanges,
      );
    },
    child: _buildTabs(context),
  );

  Widget _buildTabs(BuildContext context) => BlocBuilder<ClientChannels, List<Channel>>(
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
            bottomNavigationBar: BottomBar(
              child: Builder(
                builder: (context) {
                  final muted = ChatColors.of(context).muted;
                  final accent = Theme.of(context).colorScheme.primary;
                  // The "+" stays at the right edge, outside the scrolling tabs, so it's always in reach.
                  return Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          // The selected tab is one of the places the accent color shows.
                          labelColor: accent,
                          unselectedLabelColor: muted,
                          // 12 instead of 16, so the home icon lines up with the composer's image button below it.
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                          indicatorSize: TabBarIndicatorSize.label,
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(color: accent, width: 3.0),
                            // A rounded pill a little below the label, not a bar cut off by the tab's bottom edge.
                            borderRadius: BorderRadius.circular(3.0),
                            insets: const EdgeInsets.only(bottom: 8.0),
                          ),
                          dividerColor: Colors.transparent,
                          tabs: [
                            GestureDetector(
                              onLongPress: () {
                                unawaited(
                                  Modal.show(
                                    context: context,
                                    child: const ColdChatModal(),
                                  ),
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
                                  unawaited(
                                    Modal.show(
                                      context: context,
                                      child: ChannelModal(channel: channel),
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  height: 48.0,
                                  child: Center(child: _ChannelTabLabel(channel: channel)),
                                ),
                              ),
                            for (final conversation in whispers)
                              GestureDetector(
                                onLongPress: () {
                                  unawaited(
                                    Modal.show(
                                      context: context,
                                      child: WhisperModal(conversation: conversation),
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  height: 48.0,
                                  child: Center(child: _WhisperTabLabel(conversation: conversation)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: accent,
                        tooltip: AppLocalizations.of(context).addChannel,
                        onPressed: _openChannelSearch,
                      ),
                    ],
                  );
                },
              ),
            ),
            body: BlocBuilder<Connection, tmi.ConnectionState>(
              bloc: context.read<Client>().transmitter,
              builder: (context, connectionState) {
                // The banner claims the status-bar inset itself, so drop the
                // top inset for everything below it — otherwise the home
                // tab's large app bar and the chat view would each add it a
                // second time and leave a gap under the banner.
                final loginExpired = connectionState is tmi.ConnectionInvalidCredentials;
                final tabs = TabBarView(
                  controller: tabController,
                  children: [
                    const HomeTab(),
                    for (final channel in state)
                      ChannelView(
                        key: ObjectKey(channel),
                        channel: channel,
                      ),
                  ],
                );
                return Column(
                  children: [
                    const LoginExpiredBanner(),
                    Expanded(
                      // removePadding depends on all of MediaQuery, which changes on every frame of the keyboard
                      // animation. Only this Builder rebuilds then, with the same tabs, so the chats below don't.
                      child: Builder(
                        builder: (context) => MediaQuery.removePadding(
                          context: context,
                          removeTop: loginExpired,
                          child: tabs,
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

/// A channel tab: its name, with a red dot before it while the channel is live.
class _ChannelTabLabel extends StatelessWidget {
  final Channel channel;

  const _ChannelTabLabel({required this.channel});

  @override
  Widget build(BuildContext context) {
    final login = channel.name.replaceFirst('#', '').toLowerCase();
    return BlocSelector<LiveChannelsCubit, Set<String>, bool>(
      selector: (live) => live.contains(login),
      builder: (context, live) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            Container(
              width: 8.0,
              height: 8.0,
              decoration: const BoxDecoration(color: ChatColors.live, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6.0),
          ],
          Text(channel.name),
        ],
      ),
    );
  }
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
