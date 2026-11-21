import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../components/boxlistener.dart';
import '../components/modal.dart';
import '../components/surface.dart';
import '../data/active_account.dart';
import '../data/notifications_cubit.dart';
import '../data/twitch_account.dart';
import '../modal/coldchat.dart';
import '../modal/notifications.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/client/client.dart';
import '../tools/account_swipe.dart';

class AvatarButton extends StatefulWidget {
  /// Over the chat's messages it gets the same shadow as the chat's other floating controls; on the home tab it sits
  /// flat on the page like the search field next to it.
  final bool floating;

  const AvatarButton({super.key, this.floating = false});

  @override
  State<AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends State<AvatarButton> {
  /// How far the current vertical drag has moved since the finger went down (negative is up).
  double _dragDy = 0.0;

  void _onDragEnd(DragEndDetails details) {
    final swipe = accountSwipeFor(totalDy: _dragDy, velocityDy: details.primaryVelocity ?? 0.0);
    _dragDy = 0.0;
    if (swipe == null) return;

    final twitchAccountsBox = Hive.box<dynamic>('TwitchAccounts');
    final activeAccountHash = Hive.box<dynamic>('AccountSettings').get('activeTwitchAccount');
    final index = swipedAccountIndex(
      current: twitchAccountsBox.keys.toList().indexOf(activeAccountHash),
      count: twitchAccountsBox.length,
      swipe: swipe,
    );
    if (index == null) return;
    final nextAccount = twitchAccountsBox.getAt(index) as TwitchAccount;
    if (nextAccount.tokenData.hash == activeAccountHash) return;

    // Nothing else on screen confirms the switch except the avatar changing.
    unawaited(HapticFeedback.selectionClick());
    unawaited(setActiveAccount(context.read<Client>(), nextAccount));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsCubitState>(
      bloc: BlocProvider.of<NotificationsCubit>(context),
      builder: (BuildContext context, state) => Stack(
        children: [
          // Swiping up or down anywhere on the pill switches to the next or previous saved account. A vertical drag
          // recognizer (not a pan) claims the gesture after the same distance as the chat's scroll view, and being
          // deeper in the tree it wins when the drag starts here. The drag keeps tracking after the finger leaves the
          // pill. DragStartBehavior.down counts the distance from where the finger went down.
          GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragStart: (_) => _dragDy = 0.0,
            onVerticalDragUpdate: (details) => _dragDy += details.delta.dy,
            onVerticalDragEnd: _onDragEnd,
            onVerticalDragCancel: () => _dragDy = 0.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(128.0),
                boxShadow: widget.floating ? ChatColors.raisedShadow : null,
              ),
              child: Material(
                borderRadius: BorderRadius.circular(128.0),
                color: ChatColors.of(context).raised,
                child: InkWell(
                  onTap: () => Modal.show(
                    context: context,
                    child: const NotificationsModal(),
                  ),
                  borderRadius: BorderRadius.circular(128.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 6.0),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(Icons.notifications_none_outlined, color: Theme.of(context).colorScheme.primary),
                      ),
                      Surface(
                        borderRadius: BorderRadius.circular(128.0),
                        // The pill is one color; the avatar sits directly on it.
                        type: SurfaceType.transparent,
                        child: BoxListener(
                          box: Hive.box<dynamic>('AccountSettings'),
                          builder: (context, accountSettingsBox) {
                            return BoxListener(
                              box: Hive.box<dynamic>('TwitchAccounts'),
                              builder: (BuildContext context, Box<dynamic> twitchAccountsBox) {
                                final twitchAccount = twitchAccountsBox.values.firstWhere(
                                  (element) =>
                                      accountSettingsBox.get('activeTwitchAccount') ==
                                      (element as TwitchAccount).tokenData.hash,
                                  orElse: () => null,
                                ) as TwitchAccount?;
                                return Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(24.0),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () async {
                                      unawaited(
                                        Modal.show(
                                          context: context,
                                          child: const ColdChatModal(),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Material(
                                        borderRadius: BorderRadius.circular(24.0),
                                        clipBehavior: Clip.antiAlias,
                                        child: SizedBox(
                                          width: 32.0,
                                          height: 32.0,
                                          child: twitchAccount?.userData == null
                                              ? const Icon(Icons.person_outline_rounded)
                                              : Ink.image(
                                                  image: CachedNetworkImageProvider(twitchAccount!.userData!.avatarUrl),
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (state.unread > 0)
            Material(
              borderRadius: BorderRadius.circular(128.0),
              // type: SurfaceType.error,
              color: Colors.red,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 26.0, minHeight: 26.0),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    '${state.unread}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
