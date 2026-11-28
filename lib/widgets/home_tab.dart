import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/edge_fade.dart';
import '../components/glass.dart';
import '../components/separator.dart';
import '../components/tile.dart';
import '../data/home/channel_search_cubit.dart';
import '../data/home/home_streams_cubit.dart';
import '../data/repositories/account_repository.dart';
import '../data/twitch/stream_data.dart';
import '../l10n/app_localizations.dart';
import '../pages/home.dart';
import '../sheets/login.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/client/client.dart';
import '../tmi/client/client_lookups.dart';
import '../tools/browser_warmup.dart';
import 'avatar_button.dart';

/// Joins [channelName] (if not already joined) and switches to its tab via the
/// [HomeTabSwitcher] provided by the home page.
void joinAndOpenChannel(BuildContext context, String channelName) {
  final client = context.read<Client>();
  if (!client.channels.state.any((channel) => channel.name == channelName)) {
    client.channels.join(channelName);
    client.joiner.joinPending();
  }
  context.read<HomeTabSwitcher>().open(channelName);
}

/// The home tab: channel search, recommended and top streams. The streams come from the [HomeStreamsCubit] the home
/// page provides; the search lives (and resets) with this tab. Logged out, Twitch's search and stream lists can't be
/// used (Helix needs a login): the search field then only opens the channel typed, and a line offers to log in.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ChannelSearchCubit>(
    create: (context) {
      final accounts = context.read<AccountRepository>();
      final client = context.read<Client>();
      return ChannelSearchCubit(
        helix: () => client.helixAsActive(accounts),
      );
    },
    child: const _HomeTabView(),
  );
}

class _HomeTabView extends StatefulWidget {
  const _HomeTabView();

  @override
  State<_HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<_HomeTabView> {
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  /// Drives the floating top: the title pill fades in and the search sticks below the avatar as the page scrolls.
  final ScrollController scrollController = ScrollController();
  late final ChannelSearchRequest searchRequest = context.read<HomeTabSwitcher>().searchRequest;

  @override
  void initState() {
    super.initState();
    // TabBarView builds this tab anew whenever it is shown again: refresh lists that got old meanwhile.
    context.read<HomeStreamsCubit>().homeShown();

    searchRequest.addListener(_focusSearchIfRequested);
    // The request may have come while this tab wasn't built yet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusSearchIfRequested());
  }

  @override
  void dispose() {
    searchRequest.removeListener(_focusSearchIfRequested);
    searchFocus.dispose();
    searchTextController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // The "+" in the tab bar: put the cursor in the channel search, with any old search selected so typing replaces it.
  void _focusSearchIfRequested() {
    if (!mounted || !searchRequest.take()) return;
    searchFocus.requestFocus();
    searchTextController.selection = TextSelection(baseOffset: 0, extentOffset: searchTextController.text.length);
    // Focus set from code, mid tab animation, doesn't bring up the keyboard on Android by itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && searchFocus.hasFocus) unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
    });
  }

  // Join + switch to the channel, then reset and dismiss the search.
  void _openSearchResult(String channelName) {
    context.read<ChannelSearchCubit>().clear();
    joinAndOpenChannel(context, channelName);
    searchTextController.clear();
    FocusScope.of(context).unfocus();
  }

  // The floating top, from the status bar down: the row with the title pill and the avatar, then the search.
  static const double _rowHeight = 48.0;
  static const double _searchHeight = 48.0;
  static const double _gap = 8.0;

  /// The big "ColdChat" below the row; its height with its padding.
  static const double _bigTitleHeight = 60.0;

  /// Between the title pill's edges and its label.
  static const double _pillPadding = 18.0;

  /// The title's size in the pill: a screen title's (Material's titleLarge), well above the tabs' labels.
  static const double _pillFontSize = 22.0;

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeStreamsCubit, HomeStreamsState>(
    buildWhen: (previous, current) => previous.loggedIn != current.loggedIn,
    builder: (context, streamsState) {
      final safeTop = MediaQuery.paddingOf(context).top;
      final rowBottom = safeTop + _gap + _rowHeight;
      // Where the search is with the page at the top: below the big title.
      final searchTop = rowBottom + _bigTitleHeight;
      // The page runs under the floating top, like the chat under its controls: nothing opaque above it.
      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: context.read<HomeStreamsCubit>().refresh,
            // Below the search, not behind it.
            edgeOffset: searchTop + _searchHeight,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // Room for the big title, which the floating top draws: it turns into the title pill on scrolling.
                SliverToBoxAdapter(child: SizedBox(height: rowBottom + _bigTitleHeight)),
                // The search floats over this room, see below.
                const SliverToBoxAdapter(child: SizedBox(height: _searchHeight + 16.0)),
                BlocBuilder<ChannelSearchCubit, ChannelSearchState>(
                  builder: (context, search) => switch (search) {
                    ChannelSearchIdle() => streamsState.loggedIn ? const _StreamLists() : const _LogInForStreams(),
                    ChannelSearchLoading() => SliverList.list(children: const [_Spinner()]),
                    ChannelSearchFailed() => SliverList.list(
                      children: [Text(AppLocalizations.of(context).channelSearchFailed)],
                    ),
                    final ChannelSearchLoaded loaded => _searchResults(context, loaded),
                  },
                ),
                // The last streams can scroll up above the channel switcher floating over the list.
                SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 8.0)),
              ],
            ),
          ),
          // Soft edges where the page scrolls under the floating controls: down to below the stuck search at the top,
          // behind the channel switcher at the bottom.
          Positioned(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            child: EdgeFade.top(height: rowBottom + _gap + _searchHeight + 16.0),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: EdgeFade.bottom(height: MediaQuery.paddingOf(context).bottom + 24.0),
          ),
          // Only the floating top follows the scrolling; the page below isn't rebuilt for it.
          AnimatedBuilder(
            animation: scrollController,
            builder: (context, _) {
              final offset = scrollController.hasClients ? scrollController.offset : 0.0;
              // 0 with the page at the top, 1 once the big title has become the title pill.
              final progress = (offset / _bigTitleHeight).clamp(0.0, 1.0);
              final theme = Theme.of(context);
              final bigStyle = theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);
              final fontSize = lerpDouble(bigStyle?.fontSize ?? 28.0, _pillFontSize, progress)!;
              // The title's middle: in the page below the row, moving with it (also when pulled down to refresh),
              // and in the pill once scrolled.
              final pageMiddle = rowBottom + _bigTitleHeight / 2;
              final pillMiddle = safeTop + _gap + _rowHeight / 2;
              final titleMiddle = offset < 0.0 ? pageMiddle - offset : lerpDouble(pageMiddle, pillMiddle, progress)!;
              // The pill around the title: it grows from the bare text to the pill, fading in as it goes.
              final pillLeft = lerpDouble(16.0, 12.0, progress)!;
              final pillPadding = _pillPadding * progress;
              final pillHeight = lerpDouble(_bigTitleHeight * 0.7, _rowHeight, progress)!;
              return Stack(
                children: [
                  // Scrolls up with the page, then sticks right under the avatar row.
                  Positioned(
                    left: 12.0,
                    right: 12.0,
                    // Always the same gap below the title pill, while it moves and when it has settled.
                    top: titleMiddle + pillHeight / 2 + _gap,
                    child: _SearchPill(
                      controller: searchTextController,
                      focusNode: searchFocus,
                      onChanged: context.read<ChannelSearchCubit>().queryChanged,
                    ),
                  ),
                  Positioned(
                    left: 12.0,
                    right: 12.0,
                    top: safeTop + _gap,
                    child: const Row(
                      children: [
                        Spacer(),
                        AvatarButton(),
                      ],
                    ),
                  ),
                  // The one "ColdChat": big in the page, shrinking up into the top row as the page scrolls, with the
                  // glass pill fading in around it on the way. Bold like the name on the start screen (LoggedOutStart).
                  Positioned(
                    left: pillLeft,
                    top: titleMiddle - pillHeight / 2,
                    height: pillHeight,
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          // Faded in by the glass's own strength: an Opacity wouldn't fade its blur.
                          Positioned.fill(
                            child: Glass(strength: progress, child: const SizedBox.expand()),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: pillPadding),
                            child: Center(
                              widthFactor: 1.0,
                              child: Semantics(
                                header: true,
                                child: Text(
                                  AppLocalizations.of(context).appName,
                                  style: bigStyle?.copyWith(fontSize: fontSize),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    },
  );

  Widget _searchResults(BuildContext context, ChannelSearchLoaded search) {
    final typedChannel = search.typedChannel;
    final colors = Theme.of(context).colorScheme;
    return SliverList.list(
      children: [
        if (typedChannel != null) ...[
          Tile(
            onTap: () => _openSearchResult('#$typedChannel'),
            prefix: ClipRRect(
              borderRadius: BorderRadius.circular(48.0),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: colors.onSurface.withValues(alpha: 0.1),
                child: const Icon(Icons.add_circle_outline),
              ),
            ),
            title: search.query,
          ),
          const Separator(),
        ],
        for (final result in search.results)
          Tile(
            onTap: () => _openSearchResult('#${result.login}'),
            prefix: ClipRRect(
              borderRadius: BorderRadius.circular(48.0),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: colors.onSurface.withValues(alpha: 0.1),
                child: Ink.image(image: NetworkImage(result.profileImageUrl)),
              ),
            ),
            title: result.displayName,
            subtitle: result.isLive ? result.gameName : null,
            suffix: result.isLive && result.viewerCount != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: const BoxDecoration(color: ChatColors.live, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${result.viewerCount}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: colors.onSurface.withValues(alpha: 0.9)),
                      ),
                    ],
                  )
                : null,
          ),
      ],
    );
  }
}

/// In place of the stream lists while logged out: they come from Helix, which needs a login.
class _LogInForStreams extends StatelessWidget {
  const _LogInForStreams();

  @override
  Widget build(BuildContext context) => SliverList.list(
    children: [
      WarmsUpTwitchLogin(
        child: Tile(
          onTap: () => showTwitchLogin(context),
          prefix: Icon(Icons.login_rounded, color: Theme.of(context).colorScheme.primary),
          title: AppLocalizations.of(context).logInForSearch,
        ),
      ),
    ],
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(8.0),
    child: Center(child: CircularProgressIndicator()),
  );
}

/// The recommended streams as a carousel (hidden when none are live or they failed to load), then the top streams
/// (nothing when they failed to load). Old lists stay up while newer ones load.
class _StreamLists extends StatelessWidget {
  const _StreamLists();

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeStreamsCubit, HomeStreamsState>(
    builder: (context, state) {
      final recommended = state.recommended.streams;
      final top = state.top.streams;
      return SliverList.list(
        children: [
          if (state.recommended.isLoading) const _Spinner(),
          if (recommended != null && recommended.isNotEmpty) ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.222),
              child: CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  enlargeCenterPage: true,
                ),
                items: [
                  for (final stream in recommended)
                    StreamPreviewLarge(
                      stream: stream,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
          ],
          if (state.top.isLoading) const _Spinner(),
          if (top != null)
            for (final stream in top) StreamPreviewSmall(stream: stream),
        ],
      );
    },
  );
}

class StreamPreviewSmall extends StatelessWidget {
  const StreamPreviewSmall({
    super.key,
    required this.stream,
  });

  final StreamData stream;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => joinAndOpenChannel(context, '#${stream.userLogin}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            SizedBox(
              height: 64.0 + 16.0, // 96.0,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    stream.thumbnailUrl.replaceAll('{width}', '1920').replaceAll('{height}', '1080'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    stream.userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stream.title.trim(),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stream.gameName,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      // Red dot 8x8
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: const BoxDecoration(
                          color: ChatColors.live,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${stream.viewerCount}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 16.0),
                      const Icon(
                        Icons.alarm,
                        size: 12.0,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          '${DateTime.now().difference(stream.startedAt)}'.split('.').first,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StreamPreviewLarge extends StatelessWidget {
  const StreamPreviewLarge({
    super.key,
    required this.stream,
  });

  final StreamData stream;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: () => joinAndOpenChannel(context, '#${stream.userLogin}'),
        child: Stack(
          children: [
            Positioned.fill(
              child: Ink.image(
                image: NetworkImage(stream.thumbnailUrl.replaceAll('{width}', '1920').replaceAll('{height}', '1080')),
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 1.0),
                  ],
                  stops: const [
                    0.25,
                    1.0,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    stream.userName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stream.title.trim(),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stream.gameName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      // Red dot 8x8
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: const BoxDecoration(
                          color: ChatColors.live,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${stream.viewerCount}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 16.0),
                      Icon(
                        Icons.alarm,
                        size: 12.0,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          '${DateTime.now().difference(stream.startedAt)}'.split('.').first,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The channel search on the home tab: a glass capsule like the chat's search, with the accent search icon.
class _SearchPill extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchPill({required this.controller, required this.focusNode, required this.onChanged});

  @override
  Widget build(BuildContext context) => Glass(
    child: SizedBox(
      height: 48.0,
      child: Row(
        children: [
          const SizedBox(width: 16.0),
          Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: AppLocalizations.of(context).searchForChannels,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              controller: controller,
              focusNode: focusNode,
              // Channel names aren't words: the keyboard would "correct" them into other channels.
              autocorrect: false,
              enableSuggestions: false,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 16.0),
        ],
      ),
    ),
  );
}
