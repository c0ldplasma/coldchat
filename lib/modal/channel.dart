import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../api/twitch/twitch_profile.dart';
import '../components/modal.dart';
import '../components/tile.dart';
import '../l10n/app_localizations.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/channel_info.dart';
import '../tmi/client/client.dart';
import 'chatters.dart';
import 'components/user_modal_header.dart';

class ChannelModal extends StatefulWidget {
  final Channel channel;

  const ChannelModal({
    super.key,
    required this.channel,
  });

  @override
  State<ChannelModal> createState() => _ChannelModalState();
}

class _ChannelModalState extends State<ChannelModal> {
  Channel get channel => widget.channel;

  @override
  void initState() {
    super.initState();
    // Live status and viewer count change; the header shows the last known
    // profile meanwhile.
    unawaited(channel.refreshChannelUser());
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ChannelInfo, TwitchProfile?>(
    bloc: channel.channelInfo,
    builder: (context, state) => ListView(
      shrinkWrap: true,
      children: [
        UserModalHeader(profile: state, name: channel.name.replaceFirst('#', '')),
        Tile(
          title: AppLocalizations.of(context).chatters,
          prefix: const Icon(Icons.people_outline_outlined),
          onTap: () async {
            unawaited(
              Modal.show(
                context: context,
                child: ChattersModal(channel: channel),
              ),
            );
          },
        ),
        Tile(
          title: AppLocalizations.of(context).leaveChannel,
          prefix: const Icon(Icons.delete_forever_outlined),
          onTap: () async {
            context.read<Client>().channels.part(channel);
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}
