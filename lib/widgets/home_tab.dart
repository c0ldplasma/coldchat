import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/twitch/helix_api.dart';
import '../components/separator.dart';
import '../components/surface.dart';
import '../components/tile.dart';
import '../data/repositories/account_repository.dart';
import '../data/twitch/channel_search.dart';
import '../data/twitch/stream_data.dart';
import '../data/twitch_account.dart';
import '../l10n/app_localizations.dart';
import '../pages/home.dart';
import '../tmi/client/client.dart';
import '../tools/channel_ranking.dart';
import 'avatar_button.dart';
import 'logged_out_start.dart';

/// Joins [channelName] (if not already joined) and switches to its tab via the
/// [HomeTabSwitcher] provided by the home page.
void joinAndOpenChannel(BuildContext context, String channelName) {
  final client = context.read<Client>();
  if (!client.channels.state.any((channel) => channel.name == channelName)) {
    client.channels.join(channelName);
    client.joinPending();
  }
  context.read<HomeTabSwitcher>().open(channelName);
}

class HomeSearchBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) => const Placeholder();

  @override
  Size get preferredSize => const Size.fromHeight(48.0);
}

class SliverSearchBar extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => const SafeArea(child: Placeholder());

  @override
  double get maxExtent => 256.0;

  @override
  double get minExtent => 256.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  TwitchAccount? account;
  TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  late final ChannelSearchRequest searchRequest = context.read<HomeTabSwitcher>().searchRequest;
  Future<List<StreamData>>? recommendedStreams;
  Future<List<StreamData>>? topStreams;
  Future<List<ChannelCandidate>>? searchResults;
  Timer? searchDebounce;
  late final Listenable activeAccountListenable;

  // Starts loading the streams again. Without an account there is nothing to load.
  void refresh() {
    final account = this.account;
    if (account == null) {
      recommendedStreams = null;
      topStreams = null;
      return;
    }
    recommendedStreams = _helix(account).streams(
      userLogins: [
        'forsen',
        'btmc',
        'nymn',
        'vaxei_osu',
        'mrekkosu',
        'shigetora',
        'kitboga',
        'cdawgva',
        'gigguk',
        'vedal987',
      ],
    );
    topStreams = _helix(account).streams();
  }

  /// Helix as [account].
  HelixApi _helix(TwitchAccount account) => context.read<Client>().helix.forToken(account.tokenData);

  TwitchAccount? _activeAccount() => context.read<AccountRepository>().active;

  void _onActiveAccountChanged() {
    if (!mounted) return;
    setState(() {
      account = _activeAccount();
      refresh();
    });
  }

  @override
  void dispose() {
    activeAccountListenable.removeListener(_onActiveAccountChanged);
    searchDebounce?.cancel();
    searchRequest.removeListener(_focusSearchIfRequested);
    searchFocus.dispose();
    searchTextController.dispose();
    super.dispose();
  }

  // The "+" in the tab bar: put the cursor in the channel search, with any old search selected so typing replaces it.
  void _focusSearchIfRequested() {
    if (!mounted || !searchRequest.take() || account == null) return;
    searchFocus.requestFocus();
    searchTextController.selection = TextSelection(baseOffset: 0, extentOffset: searchTextController.text.length);
    // Focus set from code, mid tab animation, doesn't bring up the keyboard on Android by itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && searchFocus.hasFocus) unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
    });
  }

  // Waits until typing pauses, so a fast typist doesn't send a search per letter.
  void _onSearchChanged(String text) {
    searchDebounce?.cancel();
    if (normalizeChannelQuery(text).isEmpty) {
      setState(() => searchResults = null);
      return;
    }
    searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || account == null) return;
      setState(() => searchResults = searchChannels(_helix(account!), text));
    });
  }

  // Join + switch to the channel, then reset and dismiss the search.
  void _openSearchResult(String channelName) {
    searchDebounce?.cancel();
    joinAndOpenChannel(context, channelName);
    searchTextController.clear();
    FocusScope.of(context).unfocus();
    setState(() => searchResults = null);
  }

  @override
  void initState() {
    super.initState();
    account = _activeAccount();
    refresh();

    // Removed again in dispose: TabBarView disposes this page whenever another tab is shown.
    activeAccountListenable = context.read<AccountRepository>().activeChanges..addListener(_onActiveAccountChanged);

    searchRequest.addListener(_focusSearchIfRequested);
    // The request may have come while this tab wasn't built yet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusSearchIfRequested());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: activeAccountListenable,
    builder: (BuildContext context, _) {
      if (account == null) return const LoggedOutStart();

      return RefreshIndicator(
        onRefresh: () {
          setState(refresh);
          return Future.wait([?recommendedStreams, ?topStreams]);
        },
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
                            onChanged: _onSearchChanged,
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
            if (searchResults != null)
              FutureBuilder<List<ChannelCandidate>>(
                future: searchResults,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverList.list(children: [Text(AppLocalizations.of(context).channelSearchFailed)]);
                  }
                  if (!snapshot.hasData) {
                    return SliverList.list(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }
                  final query = normalizeChannelQuery(searchTextController.text);
                  final results = snapshot.data!;
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
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(color: colors.onSurface.withValues(alpha: 0.9)),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                    ],
                  );
                },
              ),
            if (searchResults == null)
              FutureBuilder<List<StreamData>>(
                future: recommendedStreams,
                builder: (context, snapshot) {
                  if (snapshot.hasError || (snapshot.data?.isEmpty ?? false)) {
                    return SliverList.list(children: const []);
                  }
                  if (!snapshot.hasData) {
                    return SliverList.list(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }
                  return SliverList.list(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.222),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                          ),
                          items: [
                            for (final stream in snapshot.data!)
                              StreamPreviewLarge(
                                stream: stream,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  );
                },
              ),
            if (searchResults == null)
              FutureBuilder<List<StreamData>>(
                future: topStreams,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SliverList.list(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }
                  return SliverList.list(
                    children: [
                      for (final stream in snapshot.data!)
                        //Padding(
                        //  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        //  child: StreamPreviewPill(stream: stream),
                        //),
                        StreamPreviewSmall(stream: stream),
                    ],
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

class StreamPreviewPill extends StatelessWidget {
  const StreamPreviewPill({
    super.key,
    required this.stream,
  });

  final StreamData stream;

  @override
  Widget build(BuildContext context) => Surface(
    type: SurfaceType.surfaceVariant,
    borderRadius: BorderRadius.circular(12.0),
    shouldClip: true,
    onTap: () {},
    child: Stack(
      children: [
        Positioned.fill(
          child: Ink.image(
            image: NetworkImage(stream.thumbnailUrl.replaceAll('{width}', '1920').replaceAll('{height}', '1080')),
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.66),
                  Colors.black.withValues(alpha: 0.66),
                ],
                stops: const [
                  0.0,
                  1.0,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stream.userName, style: Theme.of(context).textTheme.titleLarge),
              Text(
                stream.title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
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
