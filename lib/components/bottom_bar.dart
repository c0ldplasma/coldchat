import 'package:flutter/material.dart';

import '/theme/coldchat_theme.dart';

/// The bar at the bottom of the screen: the tab bar on the home page and the message composer in a chat. Uses
/// [ChatColors.bar] and hands [ChatColors.onBar] down to icons and text.
class BottomBar extends StatelessWidget {
  final Widget child;

  const BottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.of(context);
    return Material(
      color: colors.bar,
      child: SafeArea(
        top: false,
        child: IconTheme(
          data: IconThemeData(color: colors.onBar),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: colors.onBar),
            child: child,
          ),
        ),
      ),
    );
  }
}
