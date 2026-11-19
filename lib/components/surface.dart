import 'package:flutter/material.dart';

import '/theme/coldchat_theme.dart';

enum SurfaceType { primary, secondary, tertiary, error, background, surface, surfaceVariant, transparent }

class Surface extends StatelessWidget {
  final Widget child;
  final SurfaceType type;
  final bool shouldClip;
  final Function()? onTap;
  final Function()? onLongPress;
  final BorderRadius? borderRadius;

  const Surface({
    super.key,
    required this.child,
    this.shouldClip = false,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.type = SurfaceType.primary,
  });

  @override
  Widget build(BuildContext context) {
    var backgroundColor = Theme.of(context).colorScheme.errorContainer;
    var foregroundColor = Theme.of(context).colorScheme.onErrorContainer;

    switch (type) {
      case SurfaceType.primary:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        foregroundColor = Theme.of(context).colorScheme.onPrimaryContainer;
        break;
      case SurfaceType.secondary:
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
        foregroundColor = Theme.of(context).colorScheme.onSecondaryContainer;
        break;
      case SurfaceType.tertiary:
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        foregroundColor = Theme.of(context).colorScheme.onTertiaryContainer;
        break;
      case SurfaceType.error:
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
        break;
      case SurfaceType.background:
        backgroundColor = Theme.of(context).colorScheme.surface;
        foregroundColor = Theme.of(context).colorScheme.onSurface;
        break;
      case SurfaceType.surface:
        backgroundColor = Theme.of(context).colorScheme.surface;
        foregroundColor = Theme.of(context).colorScheme.onSurface;
        break;
      case SurfaceType.surfaceVariant:
        backgroundColor = ChatColors.of(context).raised;
        foregroundColor = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
      case SurfaceType.transparent:
        break;
    }

    // Only the text and icon colors are passed down, not a whole Theme: a bottom sheet opened from inside a Theme
    // widget keeps a copy of it (InheritedTheme.capture), so it would stop following light/dark and color changes.
    // A transparent surface keeps whatever colors it's placed on.
    final content = type == SurfaceType.transparent
        ? child
        : IconTheme.merge(
            data: IconThemeData(color: foregroundColor),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foregroundColor),
              child: child,
            ),
          );

    return type == SurfaceType.transparent
        ? InkWell(borderRadius: borderRadius, onTap: onTap, onLongPress: onLongPress, child: content)
        : Material(
            clipBehavior: shouldClip ? Clip.antiAlias : Clip.none,
            borderRadius: borderRadius,
            color: backgroundColor,
            child: InkWell(borderRadius: borderRadius, onTap: onTap, onLongPress: onLongPress, child: content),
          );
  }
}
