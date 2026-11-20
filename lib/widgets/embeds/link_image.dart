import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:coldchat/l10n/app_localizations.dart';

import '/data/settings/chat_settings.dart';
import '/tmi/channel/messages/embeds/image_embed.dart';
import 'embedded_image.dart';

/// An image link from chat. The image sits on whatever website the link points to, which neither Twitch nor
/// anyone else moderates, so unless the user turned on [ChatSettings.showLinkImages] it is only shown after
/// tapping "Show image". The first such tap in a session offers to turn the setting on, since few people would
/// go looking for it.
class LinkImage extends StatefulWidget {
  final ImageEmbed embed;
  final double scale;

  const LinkImage({super.key, required this.embed, this.scale = 1});

  @override
  State<LinkImage> createState() => _LinkImageState();
}

class _LinkImageState extends State<LinkImage> {
  static bool _offeredThisSession = false;

  static ChatSettings get _settings => Hive.box('Settings').get('chatSettings') as ChatSettings;

  void _reveal() {
    setState(() => widget.embed.revealed = true);
    if (_offeredThisSession || _settings.showLinkImages) return;
    _offeredThisSession = true;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.showImagesAutomatically),
        action: SnackBarAction(
          label: l10n.turnOn,
          onPressed: () {
            final settings = _settings;
            settings.showLinkImages = true;
            settings.save();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Box>(
    valueListenable: Hive.box('Settings').listenable(keys: ['chatSettings']),
    builder: (context, box, _) {
      if (widget.embed.revealed || _settings.showLinkImages) {
        return EmbeddedImage(embed: widget.embed, scale: widget.scale);
      }
      final colors = Theme.of(context).colorScheme;
      final host = Uri.tryParse(widget.embed.url)?.host ?? '';
      return Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: _reveal,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0 * widget.scale, vertical: 6.0 * widget.scale),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, size: 18.0 * widget.scale, color: colors.onSurfaceVariant),
                SizedBox(width: 6.0 * widget.scale),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.showImage(host),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14.0 * widget.scale),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
