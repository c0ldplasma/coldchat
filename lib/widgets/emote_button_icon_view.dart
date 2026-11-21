import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/emote.dart';
import '../data/emote_button_icon.dart';
import '../l10n/app_localizations.dart';

/// Draws the emote menu button's icon: the chosen emote or emoji, or Kappa.
class EmoteButtonIconView extends StatelessWidget {
  final double size;

  const EmoteButtonIconView({super.key, this.size = 24.0});

  // Rec. 709 luma weights.
  static const ColorFilter _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<EmoteButtonIcon>().changes,
    builder: (context, _) {
      final emoteButtonIcon = context.read<EmoteButtonIcon>();
      final file = emoteButtonIcon.file;
      final emoji = emoteButtonIcon.emoji;
      final Widget icon = file != null
          ? Image.file(file, height: size, filterQuality: FilterQuality.medium)
          : emoji != null
          ? SizedBox.square(
              dimension: size,
              child: FittedBox(
                child: Text(emoji, style: TextStyle(fontSize: size, height: 1.0)),
              ),
            )
          : Image.asset('assets/emote_providers/kappa.png', height: size, filterQuality: FilterQuality.medium);
      return emoteButtonIcon.grayscale ? ColorFiltered(colorFilter: _grayscale, child: icon) : icon;
    },
  );
}

/// Makes [emote] the emote menu button, or resets it to Kappa when null.
/// Returns whether it worked; shows a snackbar when the download fails.
Future<bool> chooseEmoteButtonIcon(BuildContext context, Emote? emote) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failedMessage = AppLocalizations.of(context).emoteMenuButtonDownloadFailed;
  final emoteButtonIcon = context.read<EmoteButtonIcon>();
  try {
    if (emote == null) {
      await emoteButtonIcon.reset();
    } else {
      await emoteButtonIcon.set(emote);
    }
    return true;
  } catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(failedMessage)));
    return false;
  }
}
