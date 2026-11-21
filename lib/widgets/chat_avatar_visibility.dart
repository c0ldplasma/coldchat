import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/notifications_cubit.dart';

/// Whether the chat's floating avatar is shown: with the rest of the top controls, or on its own while there are
/// unread notifications.
bool chatChromeAvatarVisible({required bool chromeShown, required int unread}) => chromeShown || unread > 0;

/// Fades [child] (the chat's avatar) in and out with the top controls, and keeps it visible while there are unread
/// notifications. While faded out it ignores taps and swipes, so an invisible avatar can't open a sheet or switch the
/// account.
class ChatAvatarVisibility extends StatelessWidget {
  final bool chromeShown;
  final Widget child;

  const ChatAvatarVisibility({super.key, required this.chromeShown, required this.child});

  @override
  Widget build(BuildContext context) => BlocSelector<NotificationsCubit, NotificationsCubitState, int>(
    selector: (state) => state.unread,
    builder: (context, unread) {
      final visible = chatChromeAvatarVisible(chromeShown: chromeShown, unread: unread);
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1.0 : 0.0,
        child: IgnorePointer(ignoring: !visible, child: child),
      );
    },
  );
}
