import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

class AvatarButton extends StatefulWidget {
  /// Over the chat's messages it gets the same shadow as the chat's other floating controls; on the home tab it sits
  /// flat on the page like the search field next to it.
  final bool floating;

  const AvatarButton({super.key, this.floating = false});

  @override
  State<AvatarButton> createState() => _AvatarButtonState();
}

enum AvatarButtonDirection {
  up,
  down,
  none,
}

class _AvatarButtonState extends State<AvatarButton> {
  AvatarButtonDirection direction = AvatarButtonDirection.none;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsCubitState>(
      bloc: BlocProvider.of<NotificationsCubit>(context),
      builder: (BuildContext context, state) => Stack(
        children: [
          DecoratedBox(
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
                                child: GestureDetector(
                                  onPanStart: (details) {
                                    direction = AvatarButtonDirection.none;
                                  },
                                  onPanUpdate: (details) {
                                    if (details.delta.dy > 1.0) {
                                      direction = AvatarButtonDirection.down;
                                    } else if (details.delta.dy < -1.0) {
                                      direction = AvatarButtonDirection.up;
                                    } else {
                                      direction = AvatarButtonDirection.none;
                                    }
                                  },
                                  onPanEnd: (details) {
                                    if (twitchAccountsBox.isEmpty) return;
                                    final activeAccountHash = accountSettingsBox.get('activeTwitchAccount');
                                    var indexOfActiveAccountHash = twitchAccountsBox.keys.toList().indexOf(
                                      activeAccountHash,
                                    );
                                    switch (direction) {
                                      case AvatarButtonDirection.up:
                                        ++indexOfActiveAccountHash;
                                        if (indexOfActiveAccountHash >= twitchAccountsBox.length) {
                                          indexOfActiveAccountHash = 0;
                                        }
                                        break;
                                      case AvatarButtonDirection.down:
                                        --indexOfActiveAccountHash;
                                        if (indexOfActiveAccountHash < 0) {
                                          indexOfActiveAccountHash = twitchAccountsBox.keys.toList().length - 1;
                                        }
                                        break;
                                      case AvatarButtonDirection.none:
                                        break;
                                    }
                                    direction = AvatarButtonDirection.none;
                                    if (indexOfActiveAccountHash < 0) return;
                                    final nextAccount =
                                        twitchAccountsBox.getAt(indexOfActiveAccountHash) as TwitchAccount;
                                    if (nextAccount.tokenData.hash == activeAccountHash) return;
                                    unawaited(setActiveAccount(context.read<Client>(), nextAccount));
                                  },
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
