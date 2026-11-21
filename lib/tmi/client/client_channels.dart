import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/channel_repository.dart';
import '../channel/channel.dart';
import '../channel/channel_state.dart';
import 'client.dart';

class ClientChannels extends Cubit<List<Channel>> {
  Client client;
  final ChannelRepository repository;

  ClientChannels(
    this.client, {
    required this.repository,
  }) : super([]) {
    joinAll(repository.channels, save: false);
  }

  void join(String channelName) {
    unawaited(repository.add(channelName));

    emit([
      ...state,
      Channel(
        client: client,
        name: channelName,
      ),
    ]);
  }

  void part(Channel channel) {
    if (channel.id != null) client.globals.bttvSocket.part(channel.id!);
    unawaited(repository.remove(channel.name));

    if (channel.state is ChannelStateWithConnection) unawaited(client.receiver.send('PART ${channel.name}'));
    if (channel.transmitterJoin.state) unawaited(client.transmitter.send('PART ${channel.name}'));

    emit([
      ...state.where((element) => element != channel),
    ]);
    // Out of the list, nothing sends it events anymore; closing it stops its emote and badge listeners.
    unawaited(channel.close());
  }

  void joinAll(List<String> channelNames, {bool save = true}) {
    if (save) {
      unawaited(repository.addAll(channelNames.where((name) => !state.any((channel) => channel.name == name))));
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
