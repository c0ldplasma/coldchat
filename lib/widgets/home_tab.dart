import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/separator.dart';
import '../components/surface.dart';
import '../components/tile.dart';
import '../data/home/channel_search_cubit.dart';
import '../data/home/home_streams_cubit.dart';
import '../data/repositories/account_repository.dart';
import '../data/twitch/stream_data.dart';
import '../l10n/app_localizations.dart';
import '../pages/home.dart';
import '../tmi/client/client.dart';
import '../tmi/client/client_lookups.dart';
import '../tools/channel_ranking.dart';
import 'avatar_button.dart';
import 'logged_out_start.dart';

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
/// page provides; the search lives (and resets) with this tab.
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
    super.dispose();
  }

  // The "+" in the tab bar: put the cursor in the channel search, with any old search selected so typing replaces it.
  void _focusSearchIfRequested() {
    if (!mounted || !searchRequest.take() || !context.read<HomeStreamsCubit>().state.loggedIn) return;
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

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeStreamsCubit, HomeStreamsState>(
    buildWhen: (previous, current) => previous.loggedIn != current.loggedIn,
    builder: (context, streamsState) {
      if (!streamsState.loggedIn) return const LoggedOutStart();

      return RefreshIndicator(
        onRefresh: context.read<HomeStreamsCubit>().refresh,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              surfaceTintColor: Colors.transparent,
              // foregroundColor: Colors.transparent,
              title: Text('ColdChat'),
              actions: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: AvatarButton(),
                ),
              ],
            ),
            SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Surface(
                    type: SurfaceType.surfaceVariant,
                    borderRadius: BorderRadius.circular(48.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 16.0),
                        Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              hintText: AppLocalizations.of(context).searchForChannels,
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            controller: searchTextController,
                            focusNode: searchFocus,
                            onChanged: context.read<ChannelSearchCubit>().queryChanged,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
            BlocBuilder<ChannelSearchCubit, ChannelSearchState>(
              builder: (context, search) => switch (search) {
                ChannelSearchIdle() => const _StreamLists(),
                ChannelSearchLoading() => SliverList.list(children: const [_Spinner()]),
                ChannelSearchFailed() => SliverList.list(
                  children: [Text(AppLocalizations.of(context).channelSearchFailed)],
                ),
                ChannelSearchLoaded(:final results) => _searchResults(context, results),
              },
            ),
          ],
        ),
      );
    },
  );

  Widget _searchResults(BuildContext context, List<ChannelCandidate> results) {
    final query = normalizeChannelQuery(searchTextController.text);
    // The typed name as a channel to join, unless the results already show it as the exact match.
    final hasExact = results.any((c) => c.login.toLowerCase() == query.toLowerCase());
    final colors = Theme.of(context).colorScheme;
    return SliverList.list(
      children: [
        if (!hasExact && query.isNotEmpty) ...[
          Tile(
            onTap: () => _openSearchResult('#${query.toLowerCase()}'),
            prefix: ClipRRect(
              borderRadius: BorderRadius.circular(48.0),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: colors.onSurface.withValues(alpha: 0.1),
                child: const Icon(Icons.add_circle_outline),
              ),
            ),
            title: query,
          ),
          const Separator(),
        ],
        for (final result in results)
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
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
                          color: Colors.red,
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
                          color: Colors.red,
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
