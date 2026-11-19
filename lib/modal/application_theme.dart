import 'package:coldchat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '/components/boxlistener.dart';
import '/data/settings/application_appearance.dart';
import '/theme/coldchat_theme.dart';
import 'components/modal_header.dart';

/// Settings → Accent color: the accents as swatches. Picking one applies it right away and leaves the sheet open, so
/// they can be compared; each swatch shows the accent as it looks in the current light or dark mode.
class ApplicationThemeModal extends StatelessWidget {
  const ApplicationThemeModal({super.key});

  @override
  Widget build(BuildContext context) => BoxListener(
        box: Hive.box('Settings'),
        builder: (context, box) {
          final current = ColdChatTheme.current(box);
          final appearance = box.get('applicationAppearance') as ApplicationAppearance;
          final brightness = Theme.of(context).brightness;
          return ListView(
            shrinkWrap: true,
            children: [
              ModalHeader(title: AppLocalizations.of(context)!.accentColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 16.0),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.9,
                  children: [
                    for (final accent in ColdChatTheme.accents)
                      _Swatch(
                        accent: accent,
                        scheme: accent.colorScheme(brightness, highContrast: appearance.highContrast),
                        selected: accent.id == current.id,
                        onTap: () => box.put(ColdChatTheme.accentKey, accent.id),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class _Swatch extends StatelessWidget {
  final AccentColor accent;
  final ColorScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({required this.accent, required this.scheme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = accent.name(AppLocalizations.of(context)!);
    return Semantics(
      selected: selected,
      button: true,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A ring around the selected one, with a gap, like the color pickers in Android's own settings.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56.0,
              height: 56.0,
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent, width: 2.0),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
                child: selected ? Icon(Icons.check_rounded, color: scheme.onPrimary) : null,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
