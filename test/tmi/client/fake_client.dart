import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coldchat/data/repositories/trigger_repository.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/tmi/cache.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/client/account_session.dart';
import 'package:coldchat/tmi/client/chat_globals.dart';
import 'package:coldchat/tmi/client/chat_history.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/client/client_channels.dart';
import 'package:coldchat/tmi/client/client_listener.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/whispers/whispers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Just what channels, whisper tabs and the chat widgets read from their client. The real [Client] opens connections
/// and timers. Anything else a test calls fails with a [NoSuchMethodError].
///
/// Without arguments it's logged out, fetches no history, has no emote or badge sources and no cache.
class FakeClient implements Client {
  final Connection? _transmitter;

  @override
  late final ChatGlobals globals;

  @override
  EmoteBadgeCache? cache;

  @override
  final AccountSession session;

  @override
  final ChatHistory history = FakeHistory();

  @override
  TriggerRepository? get triggers => null;

  @override
  late final Whispers whispers = Whispers(this);

  @override
  late ClientChannels channels = FakeChannels();

  @override
  List<ClientListener> listeners = [];

  final StreamController<String> _focusRequests = StreamController.broadcast();

  /// [transmitter] is only needed by tests that send; [ownLogin], [blockedUserIds] and [apiTokenData] are what the
  /// [session] answers; [sources] feed the [globals].
  FakeClient({
    this._transmitter,
    String? ownLogin,
    Set<String> blockedUserIds = const {},
    TokenData? apiTokenData,
    List<ChatSource> sources = const [],
  }) : session = FakeSession(ownLogin: ownLogin, blockedUserIds: blockedUserIds, apiTokenData: apiTokenData) {
    globals = ChatGlobals(sources: sources, onBadgesChanged: () {}, onUserBadgeChanged: (_) {});
  }

  @override
  Connection get transmitter => _transmitter ?? fail('This test needs a FakeClient with a transmitter.');

  @override
  Stream<String> get channelFocusRequests => _focusRequests.stream;

  @override
  void focusChannel(String channelName) => _focusRequests.add(channelName);

  /// Closes the stream behind [channelFocusRequests]; for tests that listen to it.
  Future<void> closeFocusRequests() => _focusRequests.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The account of a [FakeClient]: logged out by default, with nobody blocked.
class FakeSession implements AccountSession {
  @override
  final String? ownLogin;

  final Set<String> blockedUserIds;

  /// Null (anonymous) by default, so e.g. the user card doesn't ask Helix for a profile.
  @override
  final TokenData? apiTokenData;

  FakeSession({this.ownLogin, this.blockedUserIds = const {}, this.apiTokenData});

  @override
  bool isBlocked(String userId) => blockedUserIds.contains(userId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fetches no history.
class FakeHistory implements ChatHistory {
  @override
  Future<void> ensureRecentMessages(Channel channel) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The joined channels of a [FakeClient], without the joining.
class FakeChannels extends Cubit<List<Channel>> implements ClientChannels {
  FakeChannels() : super(const []);

  /// Shows [channels] as the joined ones.
  void show(List<Channel> channels) => emit(channels);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
