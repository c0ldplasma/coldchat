import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../components/glass.dart';
import '../../components/modal.dart';
import '../../data/emote.dart';
import '../../data/emote_cache.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../sheets/emote_section.dart';
import '../../tmi/channel/channel.dart';
import '../../tmi/client/client.dart';
import '../../tmi/emotes.dart';
import '../../tools/emotes/emote_picker_sections.dart';
import '../../tools/emotes/visible_emotes.dart';
import '../emoji_glyph.dart';
import 'emote_section_icon.dart';

class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double height;

  SectionHeaderDelegate(this.title, [this.height = 24]);

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Text(title),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

class EmotePicker extends StatefulWidget {
  final Client client;
  // Null outside of a chat (e.g. from settings): only global emotes then.
  final Channel? channel;
  final String Function() getFieldInput;
  final void Function(String) setFieldInput;
  final void Function(String) insertFieldInput;

  /// When set, the picker is choosing the emote menu button instead of typing:
  /// tapping an emote calls this, and a banner offers resetting to Kappa,
  /// which calls it with null.
  final void Function(Emote? emote)? onPickButtonIcon;

  /// Called instead of [insertFieldInput] when an emote is tapped, e.g. to show it while there's no text field.
  final void Function(Emote emote)? onShowEmote;

  /// Behind the emotes, the section headers and the section bar; the chat's color unless given.
  final Color? backgroundColor;

  /// The search field's focus, for whoever has to make room for the keyboard while it is searched.
  final FocusNode? searchFocusNode;

  /// How far the section bar floats above the picker's bottom edge; the emotes scroll on below it.
  final double bottomInset;

  /// Where the emotes end above the picker's bottom edge, e.g. at the keyboard while searching, so the last results
  /// can scroll up into view. The section bar keeps its place at the bottom.
  final double scrollBottom;

  const EmotePicker({
    super.key,
    required this.client,
    this.channel,
    required this.getFieldInput,
    required this.setFieldInput,
    required this.insertFieldInput,
    this.onPickButtonIcon,
    this.onShowEmote,
    this.backgroundColor,
    this.searchFocusNode,
    this.bottomInset = 8.0,
    this.scrollBottom = 0.0,
  });

  @override
  State<EmotePicker> createState() => _EmotePickerState();
}

class _EmotePickerState extends State<EmotePicker> {
  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();
  final EmotePickerSectionsCache sectionsCache = EmotePickerSectionsCache();
  // Each list without the emotes of hidden sections, remembered so the sections are only grouped again on a change.
  final VisibleEmotes _visibleChannelEmotes = VisibleEmotes();
  final VisibleEmotes _visibleGlobalEmotes = VisibleEmotes();
  final VisibleEmotes _visibleUserEmotes = VisibleEmotes();

  /// The keys of the hidden sections, as last built.
  Set<String> _hiddenSections = const {};

  /// The order the user arranged the sections in, as last built.
  List<String> _sectionOrder = const [];
  // One key per section title, kept across rebuilds so the section headers aren't rebuilt from scratch every time;
  // the tab bar scrolls to a section by its key.
  final Map<String, GlobalKey> groupKeys = {};

  /// Whether the search field has the keyboard: then the section bar is hidden, since the search covers every section
  /// and the room above the keyboard goes to the results.
  bool get _searching => _searchFocus.hasFocus;

  /// The search field's focus: the given one, or the picker's own (in Settings).
  late final FocusNode _ownSearchFocus = FocusNode();
  FocusNode get _searchFocus => widget.searchFocusNode ?? _ownSearchFocus;

  /// The search button at the section bar's start: back up to the search field. It doesn't take the keyboard by
  /// itself; that's a tap into the field.
  Future<void> _scrollToSearch() async {
    if (!scrollController.hasClients || scrollController.offset <= 0.0) return;
    await scrollController.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
  }

  void _onSearchFocusChanged() => setState(() {});

  /// The section bar's buttons, to keep the highlighted one in view.
  final Map<String, GlobalKey> _barKeys = {};

  /// The section in view, highlighted in the section bar; null for the first.
  String? _currentSection;

  /// The sections in the grid, in order, as last built.
  List<String> _shownSections = const [];

  /// The top-level sliver of the section titled [title] in the grid, or null when it isn't shown (filtered out by
  /// the search, or not laid out yet).
  RenderSliver? _sectionSliver(String title) {
    RenderObject? sliver = groupKeys[title]?.currentContext?.findRenderObject();
    while (sliver != null && sliver.parent is! RenderViewportBase) {
      sliver = sliver.parent;
    }
    return sliver is RenderSliver ? sliver : null;
  }

  /// Scrolls straight to where the section starts. The viewport lays out every section, so this is known even for
  /// sections far off screen; no need to detour via the bottom first.
  Future<void> _scrollToSection(String title) async {
    final section = _sectionSliver(title);
    if (section == null) return;
    final position = scrollController.position;
    final offset = section.constraints.precedingScrollExtent.clamp(position.minScrollExtent, position.maxScrollExtent);
    await position.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _updateCurrentSection() {
    if (!scrollController.hasClients) return;
    final starts = <double>[];
    final titles = <String>[];
    for (final title in _shownSections) {
      final sliver = _sectionSliver(title);
      if (sliver == null) continue;
      starts.add(sliver.constraints.precedingScrollExtent);
      titles.add(title);
    }
    final index = currentSectionIndex(starts, scrollController.offset);
    final current = index == null ? null : titles[index];
    if (current == _currentSection) return;
    setState(() => _currentSection = current);
    // Keep the highlighted button in view in the section bar, which scrolls too.
    final button = current == null ? null : _barKeys[current]?.currentContext;
    if (button != null) {
      unawaited(Scrollable.ensureVisible(button, alignment: 0.5, duration: const Duration(milliseconds: 200)));
    }
  }

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
    scrollController.addListener(_updateCurrentSection);
  }

  @override
  void didUpdateWidget(EmotePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchFocusNode != widget.searchFocusNode) {
      (oldWidget.searchFocusNode ?? _ownSearchFocus).removeListener(_onSearchFocusChanged);
      _searchFocus.addListener(_onSearchFocusChanged);
    }
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChanged);
    _ownSearchFocus.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// Long-pressing a section offers hiding its emotes.
  Future<void> _showSectionActions(EmoteSection section) => Modal.show(
    context: context,
    child: EmoteSectionModal(sectionKey: section.key, title: section.title),
  );

  // Emotes keep loading after the picker opens (Twitch's only arrive once the chat connection is up), so it rebuilds
  // when any list changes, and when a section is hidden, shown again or moved.
  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    return ListenableBuilder(
      listenable: settings.emoteSectionChanges,
      builder: (context, _) {
        _hiddenSections = settings.hiddenEmoteSections.keys.toSet();
        _sectionOrder = settings.emoteSectionOrder;
        return _buildWithEmotes(context);
      },
    );
  }

  Widget _buildWithEmotes(BuildContext context) => BlocBuilder<Emotes, List<Emote>>(
    bloc: widget.client.globals.emotes,
    builder: (context, globalEmotes) => BlocBuilder<Emotes, List<Emote>>(
      bloc: widget.client.globals.twitchUserEmotes,
      builder: (context, userEmotes) {
        final channelEmotes = widget.channel?.channelEmotes;
        if (channelEmotes == null) {
          return _buildPicker(context, channelEmotes: const [], globalEmotes: globalEmotes, userEmotes: userEmotes);
        }
        return BlocBuilder<Emotes, List<Emote>>(
          bloc: channelEmotes,
          builder: (context, channelEmotes) => _buildPicker(
            context,
            channelEmotes: channelEmotes,
            globalEmotes: globalEmotes,
            userEmotes: userEmotes,
          ),
        );
      },
    ),
  );

  Widget _buildPicker(
    BuildContext context, {
    required List<Emote> channelEmotes,
    required List<Emote> globalEmotes,
    required List<Emote> userEmotes,
  }) {
    // Grouped again only when an emote list or the hidden sections changed, filtered again only when the search did.
    final pickerSections = sectionsCache.sectionsFor(
      channelEmotes: _visibleChannelEmotes.of(channelEmotes, _hiddenSections),
      globalEmotes: _visibleGlobalEmotes.of(globalEmotes, _hiddenSections),
      userEmotes: _visibleUserEmotes.of(userEmotes, _hiddenSections),
      keepTwitchSection: !_hiddenSections.contains(emoteSectionKey(title: twitchSection)),
      order: _sectionOrder,
    );
    final sections = pickerSections.sections;
    final matchingSections = pickerSections.matching(searchController.text.toLowerCase());
    _shownSections = [for (final section in matchingSections) section.title];
    for (final section in sections) {
      groupKeys.putIfAbsent(section.title, GlobalKey.new);
    }

    final background = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    return Material(
      color: background,
      child: Stack(
        children: [
          Positioned(
            left: 0.0,
            top: 0.0,
            right: 0.0,
            bottom: widget.scrollBottom,
            child: CustomScrollView(
              controller: scrollController,
              // padding: EdgeInsets.zero,
              slivers: [
                SliverList.list(
                  children: [
                    if (widget.onPickButtonIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8.0),
                        child: Row(
                          children: [
                            Expanded(child: Text(AppLocalizations.of(context).chooseEmoteMenuButton)),
                            TextButton(
                              onPressed: () => widget.onPickButtonIcon!(null),
                              child: Text(AppLocalizations.of(context).resetToKappa),
                            ),
                          ],
                        ),
                      ),
                    // 8 points on every side and 40 high: in the emote panel's corners (radius 28) the capsule's
                    // curve (radius 20) runs parallel to the panel's, the way iOS nests rounded shapes.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                      // The highest container tone stands out on the chat and on the sheet color alike.
                      child: Material(
                        shape: const StadiumBorder(),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: SizedBox(
                          height: 40.0,
                          child: Row(
                            children: [
                              const SizedBox(width: 12.0),
                              Icon(
                                Icons.search,
                                size: 20.0,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  focusNode: _searchFocus,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: AppLocalizations.of(context).search,
                                    isCollapsed: true,
                                  ),
                                  onChanged: (text) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                for (final section in matchingSections)
                  MultiSliver(
                    key: ValueKey(section.title),
                    children: [
                      // A plain title that scrolls away with its emotes, so nothing covers the grid; the
                      // section bar shows which section is in view.
                      SliverToBoxAdapter(
                        key: groupKeys[section.title],
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () => _showSectionActions(section),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
                            child: Row(
                              children: [
                                // The section's icon from the section bar, in the title's color.
                                if (emoteSectionIcon(context, section) case final icon?) ...[
                                  SizedBox.square(
                                    dimension: 18.0,
                                    child: IconTheme.merge(
                                      data: IconThemeData(
                                        size: 18.0,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      child: icon,
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                ],
                                Flexible(
                                  child: Text(
                                    section.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (section.emotes.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: SizedBox.square(
                                dimension: 24.0,
                                child: CircularProgressIndicator(strokeWidth: 2.0),
                              ),
                            ),
                          ),
                        ),
                      // Built lazily: only the emotes on screen get a widget, not all
                      // few thousand on every rebuild.
                      // The first column's emotes line up with the section titles.
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        sliver: SliverGrid.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 32.0 + 16.0,
                          ),
                          itemCount: section.emotes.length,
                          itemBuilder: (context, index) {
                            final emote = section.emotes[index];
                            return Tooltip(
                              message: emote.name,
                              child: InkWell(
                                onTap: () async {
                                  if (widget.onPickButtonIcon != null) {
                                    widget.onPickButtonIcon!(emote);
                                  } else if (widget.onShowEmote != null) {
                                    widget.onShowEmote!(emote);
                                  } else {
                                    widget.insertFieldInput(emote.code ?? emote.name);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: EmoteGlyph(
                                    emote: emote,
                                    size: 32.0,
                                    image: () => CachedNetworkImage(
                                      imageUrl: emote.mipmap.last,
                                      cacheManager: EmoteCacheManager.instance,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                // Room to scroll the last emotes up above the section bar floating over them.
                if (!_searching) SliverToBoxAdapter(child: SizedBox(height: widget.bottomInset + 44.0 + 8.0)),
              ],
            ),
          ),
          // The section buttons in a glass capsule floating over the emotes, which scroll on below it like the
          // chat below the composer; on a fade, 8 points from the sides. In the emote panel it sits where the
          // channel switcher sits.
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            // Fades out when the search takes the keyboard and back in when it lets go of it, instead of popping:
            // the glass by its strength (an Opacity wouldn't fade its blur), the buttons and the fade behind it
            // with it. Hidden, it takes no taps.
            child: IgnorePointer(
              ignoring: _searching,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _searching ? 0.0 : 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                builder: (context, shown, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        background.withValues(alpha: 0.0),
                        background.withValues(alpha: 0.72 * shown),
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 12.0, 8.0, widget.bottomInset),
                    child: Glass(
                      strength: shown,
                      child: Opacity(
                        opacity: shown,
                        child: SizedBox(
                          height: 44.0,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            children: [
                              // First, the search: scrolls back up to the search field at the top.
                              Tooltip(
                                message: AppLocalizations.of(context).search,
                                child: InkWell(
                                  customBorder: const StadiumBorder(),
                                  onTap: _scrollToSearch,
                                  child: Container(
                                    width: 44.0,
                                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              for (final tab in sections)
                                Tooltip(
                                  key: _barKeys.putIfAbsent(tab.title, GlobalKey.new),
                                  message: tab.title,
                                  child: InkWell(
                                    customBorder: const StadiumBorder(),
                                    onTap: () => _scrollToSection(tab.title),
                                    onLongPress: () => _showSectionActions(tab),
                                    // The section in view sits on a tinted pill, like the channel switcher's tab.
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOut,
                                      width: 44.0,
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      decoration: ShapeDecoration(
                                        shape: const StadiumBorder(),
                                        color: tab.title == (_currentSection ?? sections.firstOrNull?.title)
                                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                                            : Colors.transparent,
                                      ),
                                      child: Center(
                                        child: SizedBox.square(
                                          dimension: 24.0,
                                          child: emoteSectionIcon(context, tab),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
