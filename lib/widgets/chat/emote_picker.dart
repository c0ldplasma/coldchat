import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../components/surface.dart';
import '../../data/emote.dart';
import '../../data/emote_cache.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/coldchat_theme.dart';
import '../../tmi/channel/channel.dart';
import '../../tmi/client/client.dart';
import '../../tmi/emotes.dart';
import '../../tools/emotes/emote_picker_sections.dart';
import '../emoji_glyph.dart';

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

  const EmotePicker({
    super.key,
    required this.client,
    this.channel,
    required this.getFieldInput,
    required this.setFieldInput,
    required this.insertFieldInput,
    this.onPickButtonIcon,
  });

  @override
  State<EmotePicker> createState() => _EmotePickerState();
}

class _EmotePickerState extends State<EmotePicker> {
  TextEditingController searchController = TextEditingController();
  ScrollController scrollController = ScrollController();
  final EmotePickerSectionsCache sectionsCache = EmotePickerSectionsCache();
  // One key per section title, kept across rebuilds so the section headers aren't rebuilt from scratch every time;
  // the tab bar scrolls to a section by its key.
  final Map<String, GlobalKey> groupKeys = {};

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // Emotes keep loading after the picker opens (Twitch's only arrive once the chat connection is up), so it rebuilds
  // when any list changes.
  @override
  Widget build(BuildContext context) => BlocBuilder<Emotes, List<Emote>>(
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
    // Grouped again only when an emote list changed, filtered again only when the search did.
    final pickerSections = sectionsCache.sectionsFor(
      channelEmotes: channelEmotes,
      globalEmotes: globalEmotes,
      userEmotes: userEmotes,
    );
    final sections = pickerSections.sections;
    final matchingSections = pickerSections.matching(searchController.text.toLowerCase());
    for (final section in sections) {
      groupKeys.putIfAbsent(section.title, GlobalKey.new);
    }

    const icons = {
      'Symbols': Icon(Icons.star_border_outlined),
      'Activities': Icon(Icons.local_activity_outlined),
      'Flags': Icon(Icons.flag_outlined),
      'Travel & Places': Icon(Icons.card_travel_outlined),
      'Food & Drink': Icon(Icons.fastfood_outlined),
      'Animals & Nature': Icon(Icons.pest_control_outlined),
      'People & Body': Icon(Icons.people_outline_outlined),
      'Objects': Icon(Icons.emoji_objects_outlined),
      'Component': Icon(Icons.settings_input_component_outlined),
      'Smileys & Emotion': Icon(Icons.emoji_emotions_outlined),
    };

    return Surface(
      type: SurfaceType.background,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                            child: Surface(
                              borderRadius: BorderRadius.circular(128.0),
                              // color: Colors.white,
                              type: SurfaceType.surfaceVariant,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: AppLocalizations.of(context).search,
                                    isDense: true,
                                  ),
                                  onChanged: (text) => setState(() {}),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      for (final section in matchingSections)
                        MultiSliver(
                          key: ValueKey(section.title),
                          pushPinnedChildren: true,
                          children: [
                            SliverPinnedHeader(
                              key: groupKeys[section.title],
                              child: ColoredBox(
                                color: Theme.of(context).colorScheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 4.0, right: 4.0),
                                  child: Text(section.title),
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
                            SliverGrid.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 32.0 + 16.0,
                              ),
                              itemCount: section.emotes.length,
                              itemBuilder: (context, index) {
                                final emote = section.emotes[index];
                                return Tooltip(
                                  message: emote.name,
                                  child: InkWell(
                                    onTap: () async => widget.onPickButtonIcon != null
                                        ? widget.onPickButtonIcon!(emote)
                                        : widget.insertFieldInput(emote.code ?? emote.name),
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
                          ],
                        ),
                    ],
                  ),
                ),
                Surface(
                  type: SurfaceType.background,
                  child: SizedBox(
                    height: 48.0,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final tab in sections)
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            // Thin outline so the circles stand out against the bar, which
                            // now uses the same background as the rest of the picker.
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: Surface(
                                type: SurfaceType.surface,
                                onTap: () async {
                                  // Null when search hides the section.
                                  final context = groupKeys[tab.title]?.currentContext;
                                  if (context == null) return;
                                  // Scroll straight to where the section starts. The viewport lays
                                  // out every section, so this is known even for sections far off
                                  // screen; no need to detour via the bottom first. Read it from
                                  // the section's top-level sliver rather than revealing its
                                  // pinned header, whose reported position is wrong while it is
                                  // pinned (tapping the current section scrolled to the end).
                                  RenderObject? section = context.findRenderObject();
                                  while (section != null && section.parent is! RenderViewportBase) {
                                    section = section.parent;
                                  }
                                  if (section is! RenderSliver) return;
                                  final position = scrollController.position;
                                  final offset = section.constraints.precedingScrollExtent.clamp(
                                    position.minScrollExtent,
                                    position.maxScrollExtent,
                                  );
                                  await position.animateTo(
                                    offset,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
                                borderRadius: BorderRadius.circular(64.0),
                                child: Tooltip(
                                  message: tab.title,
                                  child: AspectRatio(
                                    aspectRatio: 1 / 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child:
                                            icons[tab.title] ??
                                            sourceLogo(context, tab.title) ??
                                            firstEmoteIcon(tab.emotes),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Logo for a source's section, or null if [category] isn't a source.
  Widget? sourceLogo(BuildContext context, String category) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return switch (category) {
      'Twitch' => SvgPicture.asset(
        'assets/emote_providers/twitch.svg',
        colorFilter: const ColorFilter.mode(ChatColors.twitchPurple, BlendMode.srcIn),
      ),
      '7TV' => SvgPicture.asset(
        'assets/emote_providers/7tv.svg',
        colorFilter: ColorFilter.mode(onSurface, BlendMode.srcIn),
      ),
      'BetterTTV' => SvgPicture.asset('assets/emote_providers/bttv.svg'),
      'FrankerFaceZ' => Image.asset('assets/emote_providers/ffz.png', filterQuality: FilterQuality.medium),
      _ => null,
    };
  }

  /// Fallback for any other section: its first emote, never cut-off text.
  Widget firstEmoteIcon(List<Emote> emotes) => CachedNetworkImage(
    imageUrl: emotes.first.mipmap.last,
    cacheManager: EmoteCacheManager.instance,
    fit: BoxFit.contain,
  );
}
