import 'package:cached_network_image/cached_network_image.dart';
import 'package:coldchat/components/surface.dart';
import 'package:coldchat/modal/notifications.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/notifications_cubit.dart';
import '/components/modal.dart';
import '../modal/coldchat.dart';
import '/components/boxlistener.dart';

class AvatarButton extends StatefulWidget {
  const AvatarButton({super.key});

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
          Material(
            borderRadius: BorderRadius.circular(128.0),
            color: ChatColors.of(context).raised,
            // The same lift as the chat's other floating controls; it sits over the messages in a chat.
            elevation: 3.0,
            shadowColor: Colors.black,
            surfaceTintColor: Colors.transparent,
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
                    type: SurfaceType.background,
                    // color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: BoxListener(
                      box: Hive.box('AccountSettings'),
                      builder: (context, accountSettingsBox) {
                        return BoxListener(
                          box: Hive.box('TwitchAccounts'),
                          builder: (BuildContext context, Box twitchAccountsBox) {
                            final twitchAccount = twitchAccountsBox.values.firstWhere((element) => accountSettingsBox.get('activeTwitchAccount') == element.tokenData.hash, orElse: () => null);
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
                                  var activeAccountHash = accountSettingsBox.get('activeTwitchAccount');
                                  var indexOfActiveAccountHash = twitchAccountsBox.keys.toList().indexOf(activeAccountHash);
                                  switch (direction) {
                                    case AvatarButtonDirection.up:
                                      ++indexOfActiveAccountHash;
                                      if (indexOfActiveAccountHash >= twitchAccountsBox.length) indexOfActiveAccountHash = 0;
                                      break;
                                    case AvatarButtonDirection.down:
                                      --indexOfActiveAccountHash;
                                      if (indexOfActiveAccountHash < 0) indexOfActiveAccountHash = twitchAccountsBox.keys.toList().length - 1;
                                      break;
                                    case AvatarButtonDirection.none:
                                      break;
                                  }
                                  accountSettingsBox.put('activeTwitchAccount', twitchAccountsBox.keys.elementAt(indexOfActiveAccountHash));
                                  direction = AvatarButtonDirection.none;
                                },
                                child: InkWell(
                                  onTap: () async {
                                    Modal.show(
                                      context: context,
                                      child: const ColdChatModal(),
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
                                        child: twitchAccount == null
                                            ? const Icon(Icons.person_outline_rounded)
                                            : Ink.image(
                                                image: CachedNetworkImageProvider(twitchAccount.userData.avatarUrl),
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
