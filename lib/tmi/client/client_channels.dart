import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../channel/channel.dart';
import '../channel/channel_state.dart';
import 'client.dart';

class ClientChannels extends Cubit<List<Channel>> {
  Client client;
  Box<dynamic> channelsBox;

  ClientChannels(
    this.client, {
    required this.channelsBox,
  }) : super([]) {
    joinAll(List<String>.from(channelsBox.values), save: false);
  }

  void join(String channelName) {
    unawaited(channelsBox.add(channelName));

    emit([
      ...state,
      Channel(
        client: client,
        name: channelName,
      ),
    ]);
  }

  void part(Channel channel) {
    if (channel.id != null) client.bttvSocket.part(channel.id!);
    final x = List<String>.from(channelsBox.values).indexWhere((element) => element == channel.name);
    unawaited(channelsBox.deleteAt(x));

    if (channel.state is ChannelStateWithConnection) {
      unawaited((channel.state as ChannelStateWithConnection).receiver.send('PART ${channel.name}'));
    }

    emit([
      ...state.where((element) => element != channel),
    ]);
    // Out of the list, nothing sends it events anymore; closing it stops its emote and badge listeners.
    unawaited(channel.close());
  }

  void joinAll(List<String> channelNames, {bool save = true}) {
    if (save) {
      unawaited(channelsBox.addAll(channelNames.where((name) => !state.any((channel) => channel.name == name))));
    }

    emit([
      ...state,
      for (var channelName in channelNames)
        Channel(
          client: client,
          name: channelName,
        ),
    ]);
  }
}
