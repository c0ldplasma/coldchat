import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/emote.dart';
import '../../data/emote_cache.dart';
import '../../theme/coldchat_theme.dart';
import '../../tools/emotes/emote_picker_sections.dart';

const _emojiGroupIcons = {
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

/// The icon of [section], in the section bar and before its title: an emoji group's symbol, a channel's badge, a
/// source's logo, else its first emote. Null only for an empty section without any of these.
Widget? emoteSectionIcon(BuildContext context, EmoteSection section) =>
    _emojiGroupIcons[section.title] ??
    switch (section.iconUrl) {
      final iconUrl? => _iconImage(iconUrl),
      null => null,
    } ??
    _sourceLogo(context, section.title) ??
    _firstEmoteIcon(section.emotes);

/// Logo for a source's section, or null if [category] isn't a source.
Widget? _sourceLogo(BuildContext context, String category) {
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

/// Fallback for any other section: its first emote, never cut-off text. Null while the section is empty.
Widget? _firstEmoteIcon(List<Emote> emotes) => emotes.isEmpty ? null : _iconImage(emotes.first.mipmap.last);

/// A section's icon from [url]: a badge or an emote, so from the emote cache.
Widget _iconImage(String url) => CachedNetworkImage(
  imageUrl: url,
  cacheManager: EmoteCacheManager.instance,
  fit: BoxFit.contain,
  filterQuality: FilterQuality.medium,
);
