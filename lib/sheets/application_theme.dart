import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:provider/provider.dart';

import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/coldchat_theme.dart';
import 'components/modal_header.dart';

/// Settings → Accent color: the accents as swatches, and a custom one mixed from hue and saturation. Picking applies
/// right away and leaves the sheet open, so they can be compared; each swatch shows the accent as it looks in the
/// current light or dark mode.
class ApplicationThemeModal extends StatelessWidget {
  const ApplicationThemeModal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().changes,
    builder: (context, _) {
      final settings = context.read<SettingsRepository>();
      final current = settings.accent;
      final appearance = settings.applicationAppearance;
      final brightness = Theme.of(context).brightness;
      final isCustom = current.id == ColdChatTheme.customId;
      return ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: AppLocalizations.of(context).accentColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              children: [
                for (final accent in ColdChatTheme.accents)
                  _Swatch(
                    name: accent.name(AppLocalizations.of(context)),
                    color: accent.colorScheme(brightness, highContrast: appearance.highContrast).primary,
                    selected: accent.id == current.id,
                    onTap: () => settings.setAccent(accent),
                  ),
                _Swatch(
                  name: AppLocalizations.of(context).customColor,
                  color: isCustom ? Theme.of(context).colorScheme.primary : null,
                  selected: isCustom,
                  // Brings back the last custom color, or starts from the accent picked so far.
                  onTap: isCustom
                      ? null
                      : () => settings.setCustomAccent(
                          settings.customHue ?? current.hue,
                          settings.customChroma ?? current.chroma,
                        ),
                ),
              ],
            ),
          ),
          if (isCustom) _CustomColorEditor(settings: settings, hue: current.hue, chroma: current.chroma),
        ],
      );
    },
  );
}

class _Swatch extends StatelessWidget {
  final String name;

  /// The accent's color, or null for the custom swatch before a custom color is picked: then it shows a color wheel.
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  const _Swatch({required this.name, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onColor = color == null
        ? null
        : (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark ? Colors.white : Colors.black);
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
                border: Border.all(
                  color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  gradient: color == null ? ColdChatTheme.customAccentWheel : null,
                ),
                child: selected ? Icon(Icons.check_rounded, color: onColor) : null,
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

/// Hue and saturation sliders for the custom accent, with a preview of it in both modes. There's deliberately no
/// lightness: every accent's lightness comes from the mode, which keeps any choice readable on its background.
class _CustomColorEditor extends StatelessWidget {
  final SettingsRepository settings;
  final double hue;
  final double chroma;

  const _CustomColorEditor({required this.settings, required this.hue, required this.chroma});

  /// A mid-tone, so the slider tracks show the colors clearly in both modes.
  static Color _sample(double hue, double chroma) => Color(Hct.from(hue, chroma, 65.0).toInt());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = ColdChatTheme.custom(hue, chroma);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GradientSlider(
            label: l10n.hue,
            value: hue,
            max: 360.0,
            colors: [for (var h = 0.0; h <= 360.0; h += 30.0) _sample(h, 48.0)],
            thumbColor: _sample(hue, 48.0),
            onChanged: (value) => settings.setCustomAccent(value, chroma),
          ),
          const SizedBox(height: 16.0),
          _GradientSlider(
            label: l10n.saturation,
            value: chroma,
            max: ColdChatTheme.maxChroma,
            colors: [_sample(hue, 0.0), _sample(hue, ColdChatTheme.maxChroma)],
            thumbColor: _sample(hue, chroma),
            onChanged: (value) => settings.setCustomAccent(hue, value),
          ),
          const SizedBox(height: 20.0),
          Row(
            children: [
              Expanded(
                child: _Preview(label: l10n.light, accent: accent, brightness: Brightness.light),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _Preview(label: l10n.dark, accent: accent, brightness: Brightness.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// How the accent looks on the bottom bar in one mode: a selected tab, the add and send buttons.
class _Preview extends StatelessWidget {
  final String label;
  final AccentColor accent;
  final Brightness brightness;

  const _Preview({required this.label, required this.accent, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final scheme = accent.colorScheme(brightness);
    final bar = ChatColors.from(scheme).bar;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: bar,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          Icon(Icons.add_circle_outline_rounded, size: 20.0, color: scheme.primary),
          const SizedBox(width: 8.0),
          Icon(Icons.send_rounded, size: 20.0, color: scheme.primary),
        ],
      ),
    );
  }
}

/// A slider whose track is a color gradient. Drawn by hand because Material's slider styles its track as two flat
/// colors around the thumb.
class _GradientSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final List<Color> colors;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  const _GradientSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.colors,
    required this.thumbColor,
    required this.onChanged,
  });

  static const double _thumbRadius = 14.0;

  void _update(Offset local, double width) {
    final t = ((local.dx - _thumbRadius) / (width - 2 * _thumbRadius)).clamp(0.0, 1.0);
    onChanged((t * max).roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final step = max / 36.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8.0),
        Semantics(
          label: label,
          slider: true,
          value: '${(value / max * 100).round()}%',
          increasedValue: '${((value + step).clamp(0.0, max) / max * 100).round()}%',
          decreasedValue: '${((value - step).clamp(0.0, max) / max * 100).round()}%',
          onIncrease: () => onChanged((value + step).clamp(0.0, max)),
          onDecrease: () => onChanged((value - step).clamp(0.0, max)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final x = _thumbRadius + (value / max).clamp(0.0, 1.0) * (width - 2 * _thumbRadius);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  unawaited(HapticFeedback.selectionClick());
                  _update(details.localPosition, width);
                },
                onHorizontalDragUpdate: (details) => _update(details.localPosition, width),
                child: SizedBox(
                  height: 2 * _thumbRadius,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 12.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          gradient: LinearGradient(colors: colors),
                        ),
                      ),
                      Positioned(
                        left: x - _thumbRadius,
                        child: Container(
                          width: 2 * _thumbRadius,
                          height: 2 * _thumbRadius,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: thumbColor,
                            border: Border.all(color: Colors.white, width: 3.0),
                            boxShadow: ChatColors.raisedShadow,
                          ),
                        ),
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
  }
}
