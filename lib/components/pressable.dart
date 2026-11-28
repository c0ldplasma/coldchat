import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tap target that shrinks a little while pressed instead of showing Material's ink ripple, the way buttons react
/// on iOS. Used for the round buttons of the bottom controls. [haptic] adds a light tap on the phone when pressed.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool haptic;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.haptic = false,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) unawaitedHaptic(HapticFeedback.lightImpact());
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _setPressed(false);
                unawaitedHaptic(HapticFeedback.mediumImpact());
                widget.onLongPress!();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 150),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Haptics are fire and forget; a phone without them just does nothing.
void unawaitedHaptic(Future<void> haptic) => haptic.ignore();
