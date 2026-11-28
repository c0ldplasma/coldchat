import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/modal.dart';
import '../components/tile.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../tmi/client/client.dart';
import '../tools/emotes/emote_section_order.dart';
import '../widgets/chat/emote_section_icon.dart';
import 'components/modal_header.dart';

/// What a long press on a section in the emote picker offers: hiding its emotes, or arranging all sections.
class EmoteSectionModal extends StatelessWidget {
  /// The section's key, see `emoteSectionKey`.
  final String sectionKey;

  /// The section's title, e.g. a channel's name or `7TV`.
  final String title;

  const EmoteSectionModal({super.key, required this.sectionKey, required this.title});

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      ModalHeader(title: title),
      Tile(
        title: AppLocalizations.of(context).hideEmoteSection,
        subtitle: AppLocalizations.of(context).hideEmoteSectionSubtitle,
        prefix: const Icon(Icons.visibility_off_outlined),
        onTap: () {
          unawaited(context.read<SettingsRepository>().hideEmoteSection(sectionKey, title));
          Navigator.of(context).pop();
        },
      ),
      Tile(
        title: AppLocalizations.of(context).arrangeEmoteSections,
        prefix: const Icon(Icons.reorder),
        onTap: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          unawaited(Modal.show(context: navigator.context, child: const EmoteSectionsModal()));
        },
      ),
    ],
  );
}

/// Settings → Emotes → Emote sections: every section of the emote picker, to drag into another order and to hide or
/// show again. Lists the sections of every open chat and every hidden one (see [arrangeableEmoteSections]).
class EmoteSectionsModal extends StatefulWidget {
  const EmoteSectionsModal({super.key});

  @override
  State<EmoteSectionsModal> createState() => _EmoteSectionsModalState();
}

class _EmoteSectionsModalState extends State<EmoteSectionsModal> {
  /// The order just dragged into, until the settings have it: the list mustn't jump back for a frame.
  List<String>? _order;

  /// Asks before going back to the default order, saying that hidden sections stay hidden.
  Future<void> _confirmReset(SettingsRepository settings) async {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetEmoteSectionOrderTitle),
        content: Text(l10n.resetEmoteSectionOrderDescription),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: error),
            child: Text(l10n.resetEmoteSectionOrderConfirm),
          ),
        ],
      ),
    );
    if (reset != true || !mounted) return;
    setState(() => _order = null);
    await settings.resetEmoteSectionOrder();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    final client = context.read<Client>();
    return ListenableBuilder(
      listenable: settings.emoteSectionChanges,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final hidden = settings.hiddenEmoteSections;
        final saved = settings.emoteSectionOrder;
        final sections = arrangeableEmoteSections(
          channelEmoteLists: [for (final channel in client.channels.state) channel.channelEmotes.state],
          globalEmotes: client.globals.emotes.state,
          userEmotes: client.globals.twitchUserEmotes.state,
          hidden: hidden,
          savedOrder: _order ?? saved,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalHeader(
              title: l10n.emoteSections,
              // An icon like other sheets' header actions: its name doesn't fit next to the title in every language.
              trailing: saved.isEmpty && _order == null
                  ? null
                  : Tooltip(
                      message: l10n.resetEmoteSectionOrder,
                      child: InkWell(
                        onTap: () => _confirmReset(settings),
                        borderRadius: BorderRadius.circular(24.0),
                        child: SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: Icon(Icons.restart_alt, color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
            ),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: sections.length,
                onReorderItem: (oldIndex, newIndex) {
                  final order = reorderedSectionKeys(sections, oldIndex, newIndex);
                  setState(() => _order = order);
                  unawaited(settings.setEmoteSectionOrder(order));
                },
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final isHidden = hidden.containsKey(section.key);
                  return Material(
                    key: ValueKey(section.key),
                    type: MaterialType.transparency,
                    child: Tile(
                      title: section.title,
                      subtitle: isHidden ? l10n.emoteSectionHidden : null,
                      prefix: Opacity(
                        opacity: isHidden ? 0.4 : 1.0,
                        child: Center(
                          child: SizedBox.square(
                            dimension: 24.0,
                            child: emoteSectionIcon(context, section) ?? const Icon(Icons.emoji_emotions_outlined),
                          ),
                        ),
                      ),
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: isHidden ? l10n.showEmoteSection : l10n.hideEmoteSection,
                            icon: Icon(isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => isHidden
                                ? settings.showEmoteSection(section.key)
                                : settings.hideEmoteSection(section.key, section.title),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.drag_handle)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
