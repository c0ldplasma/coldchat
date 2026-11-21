import 'package:flutter/material.dart';

class Tile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? prefix;
  final Widget? suffix;
  final bool primary;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const Tile({
    super.key,
    required this.title,
    this.subtitle,
    this.prefix,
    this.suffix,
    this.primary = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    onLongPress: onLongPress,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(width: primary ? 0.0 : 2.0),
          SizedBox(
            width: primary ? 40.0 : 36.0,
            height: primary ? 40.0 : 36.0,
            // Menu icons in the accent color, like Android's own settings. An icon with its own color keeps it.
            child: IconTheme.merge(
              data: IconThemeData(color: Theme.of(context).colorScheme.primary),
              child: prefix ?? const SizedBox.shrink(),
            ),
          ),
          SizedBox(width: 16.0 + (primary ? 0.0 : 2.0)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          // const Spacer(),
          SizedBox(width: 16.0 + (primary ? 0.0 : 2.0)),
          SizedBox(
            // width: primary ? 40.0 : 36.0,
            // height: primary ? 40.0 : 36.0,
            child: suffix,
          ),
          SizedBox(width: primary ? 0.0 : 2.0),
        ],
      ),
    ),
  );
}
