import 'package:flutter/material.dart';

/// The soft edge where content scrolls under floating controls (iOS's scroll edge effect): the page's background
/// fades in toward the screen's edge, so the clock and the controls stay readable over busy content without a hard
/// line cutting it. Goes below the controls and above the content, and takes no touches.
class EdgeFade extends StatelessWidget {
  /// Which edge it fades toward.
  final VerticalDirection toward;

  /// How far it reaches from the edge.
  final double height;

  const EdgeFade.top({super.key, required this.height}) : toward = VerticalDirection.up;

  const EdgeFade.bottom({super.key, required this.height}) : toward = VerticalDirection.down;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final edgeAtTop = toward == VerticalDirection.up;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: edgeAtTop ? Alignment.topCenter : Alignment.bottomCenter,
              end: edgeAtTop ? Alignment.bottomCenter : Alignment.topCenter,
              // At the top it must carry the clock and battery over busy content, with nothing else (iOS draws no blur
              // behind the status bar for Flutter): nearly opaque at the edge, still dark through the status bar's
              // height, then fading out. At the bottom the glass controls do most of the calming.
              colors: edgeAtTop
                  ? [surface.withValues(alpha: 0.94), surface.withValues(alpha: 0.82), surface.withValues(alpha: 0.0)]
                  : [surface.withValues(alpha: 0.72), surface.withValues(alpha: 0.0)],
              stops: edgeAtTop ? const [0.0, 0.45, 1.0] : null,
            ),
          ),
        ),
      ),
    );
  }
}
