import 'package:flutter/material.dart';

import '/theme/coldchat_theme.dart';

class Modal extends StatelessWidget {
  final Widget child;
  final Clip clipBehavior;

  const Modal({
    super.key,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: ChatColors.of(context).sheet,
              clipBehavior: clipBehavior,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(8.0), topLeft: Radius.circular(8.0)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1024.0,
                  // Up to a small gap below the status bar, so longer sheets like
                  // settings fit without scrolling but still read as a sheet.
                  maxHeight: mediaQuery.size.height - mediaQuery.viewInsets.vertical - mediaQuery.padding.top - 32.0,
                ),
                child: SafeArea(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build2(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0) + MediaQuery.of(context).viewInsets,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: ChatColors.of(context).sheet,
              clipBehavior: clipBehavior,
              borderRadius: BorderRadius.circular(8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1024.0,
                  maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.vertical) * 0.8,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required Widget child,
    Clip clipBehavior = Clip.antiAlias,
    bool enableDrag = true,
  }) async =>
      await showModalBottomSheet(
        // Opened from the navigator itself rather than [context]: a sheet keeps a frozen copy of every inherited style
        // between the context it's opened from and the navigator (InheritedTheme.capture), like the icon colors of the
        // tab bar or a Surface, and then wouldn't follow a switch between light and dark while it's open.
        context: Navigator.of(context).context,
        enableDrag: enableDrag,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Modal(
            clipBehavior: clipBehavior,
            child: child,
          );
        },
      );
}
