import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/coldchat_theme.dart';

/// A translucent control floating over moving content: the content behind it is blurred and tinted with
/// [ChatColors.glass], with a hairline [ChatColors.glassBorder] around it, like the bars and fields of iOS and the
/// floating toolbars of Material 3 Expressive. Passes [ChatColors] text and icon colors down: muted icons and
/// regular text, so a glass control looks the same wherever it is placed.
///
/// [shape] is a stadium (capsule) by default; pass a [RoundedRectangleBorder] for cards.
class Glass extends StatelessWidget {
  final Widget child;
  final ShapeBorder shape;

  /// How much of the glass there is, to fade it in or out: blur, tint and edge all scale with it. An [Opacity] around
  /// a [Glass] doesn't do: it fades the tint but not the blur, which then pops in at full strength.
  final double strength;

  const Glass({super.key, required this.child, this.shape = const StadiumBorder(), this.strength = 1.0});

  /// A card shape for the panels above the composer.
  static const ShapeBorder card = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22.0)));

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.of(context);
    final theme = Theme.of(context);
    final glass = colors.glass.withValues(alpha: colors.glass.a * strength);
    final edge = colors.glassBorder.withValues(alpha: colors.glassBorder.a * strength);
    final outlined = switch (shape) {
      final OutlinedBorder border => border.copyWith(side: BorderSide(color: edge, width: 0.5)),
      _ => shape,
    };
    final content = DecoratedBox(
      decoration: ShapeDecoration(color: glass, shape: outlined),
      // Ink of taps inside (list tiles, buttons) is drawn on this, above the blur, not on the page below it.
      child: Material(
        type: MaterialType.transparency,
        child: IconTheme.merge(
          data: IconThemeData(color: colors.muted),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: theme.colorScheme.onSurface),
            child: child,
          ),
        ),
      ),
    );
    if (strength <= 0.0) return content;
    final sigma = 24.0 * strength;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: content,
      ),
    );
  }
}
