import 'package:collection/collection.dart';

import '../../data/emote.dart';
import 'emote_picker_sections.dart';

/// Puts [sections] (in their default order) in the order the user arranged ([savedOrder], section keys). Sections
/// that were never arranged, like a new sub's, go right after the section before them in the default order, so they
/// turn up where they would have been. Keys in [savedOrder] without a section here (e.g. a source a chat has no emotes
/// of) are skipped, and keep their place for where they are.
List<T> orderSections<T>(List<T> sections, String Function(T section) keyOf, List<String> savedOrder) {
  if (savedOrder.isEmpty) return sections;
  final rank = {for (final (index, key) in savedOrder.indexed) key: index};
  final ordered = sections.where((section) => rank.containsKey(keyOf(section))).toList()
    ..sort((a, b) => rank[keyOf(a)]!.compareTo(rank[keyOf(b)]!));
  for (final (index, section) in sections.indexed) {
    if (rank.containsKey(keyOf(section))) continue;
    // Its default predecessor is already placed: the arranged ones all are, and the others come in default order.
    final at = index == 0 ? 0 : ordered.indexOf(sections[index - 1]) + 1;
    ordered.insert(at, section);
  }
  return ordered;
}

/// The sections Settings → Chat → Emote sections lists, in the user's order: those of the global emotes, the user's
/// Twitch emotes and the channel emotes of every open chat ([channelEmoteLists]), and every hidden one ([hidden], key
/// to title), also when it has no emotes right now (it can be shown again). Hidden sections are listed with their
/// emotes; whether a section is hidden is up to the caller.
List<EmoteSection> arrangeableEmoteSections({
  required List<List<Emote>> channelEmoteLists,
  required List<Emote> globalEmotes,
  required List<Emote> userEmotes,
  required Map<String, String> hidden,
  required List<String> savedOrder,
}) {
  final sections = EmotePickerSections.group(
    channelEmotes: [for (final list in channelEmoteLists) ...list],
    globalEmotes: globalEmotes,
    userEmotes: userEmotes,
  ).sections;
  final keys = {for (final section in sections) section.key};
  final all = [
    ...sections,
    for (final MapEntry(:key, value: title) in hidden.entries)
      if (!keys.contains(key)) EmoteSection(title, const [], ownerId: key.startsWith(_titleKeyPrefix) ? null : key),
  ];
  return orderSections(all, (section) => section.key, savedOrder);
}

final _titleKeyPrefix = emoteSectionKey(title: '');

/// The keys of [sections], to save as their order after the user moved the one at [oldIndex] to [newIndex] (as
/// `ReorderableListView.onReorderItem` gives them: [newIndex] is its place in the new order).
List<String> reorderedSectionKeys(List<EmoteSection> sections, int oldIndex, int newIndex) {
  final keys = [for (final section in sections) section.key];
  keys.insert(newIndex, keys.removeAt(oldIndex));
  return keys;
}

/// Whether [a] and [b] are the same order.
bool sameOrder(List<String> a, List<String> b) => const ListEquality<String>().equals(a, b);
