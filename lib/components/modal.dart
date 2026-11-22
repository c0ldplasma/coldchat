import 'package:flutter/material.dart';

import '../theme/coldchat_theme.dart';

class Modal extends StatelessWidget {
  final Widget child;
  final Clip clipBehavior;

  const Modal({
    super.key,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  });

  /// The gap between the status bar and the top of a sheet as tall as the screen allows, so it still reads as a sheet.
  static const topGap = 32.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    // The route's SafeArea (useSafeArea in [show]) already keeps the sheet below the status bar, so the space given
    // here is what's left under it.
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: ChatColors.of(context).sheet,
            clipBehavior: clipBehavior,
            borderRadius: const BorderRadius.only(topRight: Radius.circular(8.0), topLeft: Radius.circular(8.0)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1024.0,
                maxHeight: modalMaxHeight(constraints.maxHeight),
              ),
              child: SafeArea(child: child),
            ),
          ),
        ],
      ),
    ),
  );

  static Future<void> show({
    required BuildContext context,
    required Widget child,
    Clip clipBehavior = Clip.antiAlias,
    bool enableDrag = true,
  }) async => await showModalBottomSheet(
    // Opened from the navigator itself rather than [context]: a sheet keeps a frozen copy of every inherited style
    // between the context it's opened from and the navigator (InheritedTheme.capture), like the icon colors of the
    // tab bar or a Surface, and then wouldn't follow a switch between light and dark while it's open.
    context: Navigator.of(context).context,
    enableDrag: enableDrag,
    isScrollControlled: true,
    // Without it the route removes the status bar's padding from the sheet, and a tall sheet slides under it.
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Modal(
        clipBehavior: clipBehavior,
        child: child,
      );
    },
  );
}

/// The height a sheet may take of the [available] height below the status bar (and above the keyboard): all of it but
/// [Modal.topGap], never negative.
double modalMaxHeight(double available) => (available - Modal.topGap).clamp(0.0, double.infinity);
