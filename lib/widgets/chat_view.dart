import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/size_reporter.dart';
import '../components/surface.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/channel_message.dart';
import '../tmi/channel/channel_messages.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import 'avatar_button.dart';
import 'chat_avatar_visibility.dart';
import 'chat_message.dart';

/// The chat list's top padding. Scrolled all the way up, the oldest message has to sit below the floating search bar
/// and avatar, which take [overlayHeight] from the top of the chat (safe area included), instead of behind them.
/// [insetTop] is the top of the padding the chat was given; until the overlay is measured the list keeps 8 px below it.
double chatListTopPadding({required double insetTop, required double overlayHeight}) =>
    max(insetTop + 8.0, overlayHeight);

class ChatView extends StatefulWidget {
  final Channel channel;
  final bool Function(ChannelMessage message)? filter;
  final EdgeInsets? padding;

  const ChatView({
    super.key,
    required this.channel,
    this.filter,
    this.padding,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  List<ChannelMessage>? scrollMessages;

  /// The [ChatMessage] built for each message. Giving the list the same widget again lets Flutter skip rebuilding a
  /// message that didn't change when another one arrives. Messages rebuilt in place ([ChannelMessages.revision]) and a
  /// changed message appearance need new widgets, so then all of them are dropped.
  Expando<ChatMessage> _messageWidgets = Expando();
  int _messageWidgetsRevision = 0;
  late final Listenable _messageAppearanceChanges;

  void _dropMessageWidgets() => _messageWidgets = Expando();

  ChatMessage _messageWidget(ChannelMessage message) =>
      _messageWidgets[message] ??= ChatMessage(key: ObjectKey(message), message: message);

  /// Height of the search bar row (and avatar) floating over the top of the list, measured after layout. It's laid out
  /// even while faded out, so it stays the same whether the controls are shown or not.
  double _overlayHeight = 0.0;

  void _onOverlaySize(Size size) {
    if (!mounted || size.height == _overlayHeight) return;
    setState(() => _overlayHeight = size.height);
  }

  // Keep the top chrome (search bar, notifications bell, scroll-to-bottom
  // button) visible for a while after the user stops interacting instead of
  // hiding it the instant they reach the bottom.
  bool _chromeVisible = false;
  Timer? _hideChromeTimer;
  static const Duration _chromeLinger = Duration(seconds: 3);
  static const Duration _chromeStartupLinger = Duration(seconds: 6);

  void _showChrome({Duration linger = _chromeLinger}) {
    _hideChromeTimer?.cancel();
    if (!_chromeVisible) {
      _chromeVisible = true;
      if (mounted) setState(() {});
    }
    _hideChromeTimer = Timer(linger, () {
      if (!mounted) return;
      setState(() => _chromeVisible = false);
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(widget.channel.client.ensureRecentMessages(widget.channel));
    // Show the chrome a bit longer right after the view appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showChrome(linger: _chromeStartupLinger));
    searchFocusNode.addListener(() => setState(() {}));
    _messageAppearanceChanges = context.read<SettingsRepository>().messageAppearanceChanges
      ..addListener(_dropMessageWidgets);
  }

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // [ChannelMessages.revision] counts per channel.
    if (oldWidget.channel != widget.channel) _dropMessageWidgets();
  }

  @override
  void dispose() {
    _hideChromeTimer?.cancel();
    _messageAppearanceChanges.removeListener(_dropMessageWidgets);
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().messageAppearanceChanges,
    builder: (context, _) => BlocBuilder<ChannelMessages, List<ChannelMessage>>(
      bloc: widget.channel.channelMessages,
      buildWhen: (state1, state2) => scrollMessages == null,
      builder: (context, state) {
        final searching = searchController.text.isNotEmpty;
        // Never fade out the search bar while it's in use, or the user can't
        // tell why the chat is filtered.
        final chromeShown = scrollMessages != null || _chromeVisible || searching || searchFocusNode.hasFocus;
        var messages = (scrollMessages ?? state).reversed;
        // Filter both the live list and the paused snapshot. Filtering only
        // the snapshot made the search depend on the scroll position.
        if (searching) {
          messages = messages
              .where(
                (element) =>
                    element is ChannelMessageChat &&
                    '${(element.user.displayName ?? element.user.login)?.toLowerCase()}: ${element.body.toLowerCase()}'
                        .contains(searchController.text.toLowerCase()),
              )
              .toList();
        }
        if (widget.filter != null) messages = messages.where((element) => widget.filter!(element)).toList();
        final revision = widget.channel.channelMessages.revision;
        if (revision != _messageWidgetsRevision) {
          _messageWidgetsRevision = revision;
          _dropMessageWidgets();
        }
        // Where each message is now, built on the first lookup of this build. A new message goes in at index 0 (the
        // list is reversed) and moves every other one up by one; this lets the list find a message's new index and
        // keep its element, instead of giving its old element to whatever message is at its old index now.
        Map<ChannelMessage, int>? indices;
        return Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollUpdateNotification || scrollNotification is ScrollStartNotification) {
                    _showChrome();
                  }
                  if (scrollNotification is ScrollUpdateNotification &&
                      scrollMessages == null &&
                      scrollController.position.pixels > scrollController.position.minScrollExtent) {
                    scrollMessages = state;
                    setState(() {});
                  }
                  if (scrollNotification is ScrollEndNotification &&
                      scrollMessages != null &&
                      scrollController.position.pixels <= scrollController.position.minScrollExtent) {
                    scrollMessages = null;
                    setState(() {});
                  }
                  return true;
                },
                child: ListView.builder(
                  // padding: MediaQuery.of(context).padding.copyWith(bottom: MediaQuery.of(context).padding.bottom + 8.0),
                  padding: (widget.padding ?? EdgeInsets.zero).copyWith(
                    top: chatListTopPadding(insetTop: widget.padding?.top ?? 0, overlayHeight: _overlayHeight),
                    bottom: (widget.padding?.bottom ?? 0) + 8.0,
                  ),
                  reverse: true,
                  // A chat too short to scroll would otherwise ignore drags, and the scroll notifications above are
                  // the only way to bring back the hidden search bar, bell and avatar.
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: messages.length,
                  controller: scrollController,
                  itemBuilder: (BuildContext context, int index) => _messageWidget(messages.elementAt(index)),
                  findChildIndexCallback: (key) {
                    if (key is! ObjectKey) return null;
                    indices ??= Map.identity()
                      ..addEntries(messages.indexed.map((entry) => MapEntry(entry.$2, entry.$1)));
                    return indices![key.value];
                  },
                ),
              ),
            ),
            // Material(
            //   color: Theme.of(context).colorScheme.primaryContainer,
            //   child: Column(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       if (scrollMessages != null)
            //         Ink(
            //           color: Theme.of(context).colorScheme.tertiaryContainer,
            //           height: 32.0 + 24.0,
            //           child: InkWell(
            //             onTap: () {
            //               scrollMessages = null;
            //               setState(() {});
            //               WidgetsBinding.instance.scheduleFrameCallback((_) {
            //                 scrollController.jumpTo(scrollController.position.minScrollExtent);
            //               });
            //             },
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Icon(
            //                   Icons.arrow_downward_rounded,
            //                   color: Theme.of(context).colorScheme.onTertiaryContainer,
            //                 ),
            //                 const SizedBox(width: 4.0),
            //                 Text(
            //                   AppLocalizations.of(context).scrollToBottom,
            //                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //                         color: Theme.of(context).colorScheme.onTertiaryContainer,
            //                       ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ),
            //     ],
            //   ),
            // ),
            SizeReporter(
              onSize: _onOverlaySize,
              child: SafeArea(
                // The bottom inset is below the composer, not under this row; it would only inflate the measured height.
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: chromeShown ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !chromeShown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(128.0),
                                boxShadow: ChatColors.raisedShadow,
                              ),
                              child: Surface(
                                borderRadius: BorderRadius.circular(128.0),
                                type: SurfaceType.surfaceVariant,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: TextField(
                                    controller: searchController,
                                    focusNode: searchFocusNode,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: AppLocalizations.of(context).search,
                                      isDense: true,
                                      // Like the home tab's search field: accent icon on the neutral pill.
                                      prefixIcon: Padding(
                                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                                        child: Icon(
                                          Icons.search,
                                          size: 20.0,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      prefixIconConstraints: const BoxConstraints(),
                                      suffixIconConstraints: const BoxConstraints(),
                                      suffixIcon: searching
                                          ? GestureDetector(
                                              onTap: () => setState(() => searchController.clear()),
                                              child: const Icon(Icons.close_rounded, size: 20.0),
                                            )
                                          : null,
                                    ),
                                    onChanged: (text) => setState(() {}),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.filter == null)
                      ChatAvatarVisibility(
                        chromeShown: chromeShown,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
                          child: AvatarButton(floating: true),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24.0,
              right: 24.0,
              child: SafeArea(
                bottom: false,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: scrollMessages != null ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: scrollMessages == null,
                    // Styled like the chat's other floating controls (the search pill), with a shadow to lift it off
                    // the messages behind it.
                    child: DecoratedBox(
                      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: ChatColors.raisedShadow),
                      child: Surface(
                        onTap: () {
                          scrollMessages = null;
                          setState(() {});
                          WidgetsBinding.instance.scheduleFrameCallback((_) {
                            scrollController.jumpTo(scrollController.position.minScrollExtent);
                          });
                          searchController.text = '';
                        },
                        borderRadius: BorderRadius.circular(128.0),
                        type: SurfaceType.surfaceVariant,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
