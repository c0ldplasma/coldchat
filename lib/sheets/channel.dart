import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/twitch/twitch_profile.dart';
import '../components/modal.dart';
import '../components/tile.dart';
import '../data/live/live_channels_cubit.dart';
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
        // Only while the channel is live: there is nothing to watch otherwise.
        if (isChannelLive(login: channel.name, profile: state, live: context.watch<LiveChannelsCubit>().state))
          Tile(
            title: AppLocalizations.of(context).watchOnTwitch,
            prefix: const Icon(Icons.play_arrow_rounded),
            // The system opens twitch.tv links in the Twitch app when it is installed, in the browser otherwise.
            onTap: () => unawaited(
              launchUrl(
                Uri.parse('https://www.twitch.tv/${channel.name.replaceFirst('#', '')}'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
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
