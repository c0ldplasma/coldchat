import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:collection/collection.dart';

import '../../api/api_client.dart';
import '../../api/betterttv/betterttv.dart';
import '../../api/dankchat/dankchat.dart';
import '../../api/emojis/emoji_data.dart';
import '../../api/frankerfacez/frankerfacez.dart';
import '../../api/recentmessages/recentmessages.dart';
import '../../api/seventv/seventv.dart';
import '../../api/twitch/eventsub_socket.dart';
import '../../api/twitch/helix_api.dart';
import '../../api/twitch/twitch_auth_api.dart';
import '../../data/emote.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../data/repositories/emote_badge_cache_repository.dart';
import '../../data/repositories/trigger_repository.dart';
import '../../data/repositories/whisper_repository.dart';
import '../../data/twitch/token_data.dart';
import '../../data/twitch_account.dart';
import '../../irc/message.dart' as irc;
import '../../providers/betterttv.dart';
import '../../providers/dankchat.dart';
import '../../providers/emojis.dart';
import '../../providers/frankerfacez.dart';
import '../../providers/provider.dart';
import '../../providers/seventv.dart';
import '../../providers/twitch.dart';
import '../cache.dart';
import '../channel/channel.dart';
import '../channel/channel_event.dart';
import '../channel/channel_message.dart';
import '../channel/channel_state.dart';
import '../channel/messages/channel_message_ban.dart';
import '../channel/messages/channel_message_chat.dart';
import '../channel/messages/channel_message_notice.dart';
import '../connection/connection.dart';
import '../connection/connection_event.dart';
import '../connection/connection_state.dart';
import '../irc_log.dart';
import '../whispers/whispers.dart';
import 'account_session.dart';
import 'channel_joiner.dart';
import 'chat_globals.dart';
import 'chat_history.dart';
import 'client_channels.dart';
import 'client_listener.dart';

/// The chat client. It has two IRC connections:
///
/// - The [receiver] reads the chat. It is always anonymous (Twitch's `justinfan` nick, no token), connects at startup
///   whether or not there is an account, and is never reconnected by logging in, switching accounts or logging out,
///   so the chat stays live through all of them.
/// - The [transmitter] is logged in as the active account and sends messages. It joins the channels too, but only
///   for what Twitch tells the account there: USERSTATE (moderator status) and the NOTICEs answering its messages.
///   Chat traffic arriving on it is ignored, the receiver already shows it.
class Client implements AccountConnector {
  /// Reads the chat, anonymously. See [Client].
  final Connection receiver;

  /// Sends as the active account; disconnected while logged out. See [Client].
  final Connection transmitter;

  /// The app's HTTP client, shared by every API below.
  final ApiClient api;

  /// Helix as the account in [AccountSession.apiTokenData]. [HelixApi.forToken] sends as another one.
  late final HelixApi helix = HelixApi(api, () => session.apiTokenData);

  late final TwitchAuthApi twitchAuth = TwitchAuthApi(api);

  /// The logged-in account: logging in and out, validating the login, the block list and the own chat color.
  late final AccountSession session;

  final List<Provider>? _customProviders;

  late final List<Provider> providers =
      _customProviders ??
      [
        SevenTVProvider(SevenTvApi(api)),
        BetterTTVProvider(BttvApi(api)),
        FrankerFaceZProvider(FfzApi(api)),
        DankChatProvider(DankChatApi(api)),
        TwitchProvider(helix: helix),
        EmojiProvider(EmojiDataApi(api)),
      ];

  late ClientChannels channels;
  late final Whispers whispers;
  late final EventSubSocket eventSub = EventSubSocket(helix: helix, onWhisper: (whisper) => whispers.receive(whisper));

  /// Where emotes, badges and history are kept between launches; null without a cache repository (tests). Set once in
  /// the constructor and shared with [globals] and [history], so it can't be replaced behind their backs.
  late final EmoteBadgeCache? cache;

  List<ClientListener> listeners = [];

  /// The global emotes and badges, the account's Twitch emotes and the BetterTTV Pro badges.
  late final ChatGlobals globals;

  /// The message and user triggers that highlight or block messages. Null in tests, then there are none.
  final TriggerRepository? triggers;

  /// The chat history of the channels, from the recent-messages service and the cache.
  late final ChatHistory history;

  /// Joins the channels on both connections.
  late final ChannelJoiner joiner;

  final StreamController<String> _channelFocusRequests = StreamController.broadcast();

  /// Channels (by name) whose tab should be shown, e.g. after Reply or Mention in a message sheet. The home page
  /// switches to them; the sheets are above it, out of reach of its `HomeTabSwitcher`.
  Stream<String> get channelFocusRequests => _channelFocusRequests.stream;

  /// Asks the home page to show the tab of the channel named [channelName], if it has one.
  void focusChannel(String channelName) {
    if (!_channelFocusRequests.isClosed) _channelFocusRequests.add(channelName);
  }

  /// [receiver], [transmitter] and [providers] are replaceable for tests; by default they're the real connections and
  /// the emote and badge providers.
  Client({
    required this.api,
    TwitchAccount? twitchAccount,
    AccountRepository? accounts,
    this.triggers,
    RecentMessages? recentMessages,
    required ChannelRepository channelRepository,
    EmoteBadgeCacheRepository? cacheRepository,
    WhisperRepository? whisperRepository,
    Connection? receiver,
    Connection? transmitter,
    List<Provider>? providers,
  }) : receiver = receiver ?? Connection(name: 'receiver'),
       // The transmitter doesn't need to know who else joins, which in a big channel is a line every few seconds.
       transmitter = transmitter ?? Connection(name: 'transmitter', membership: false),
       _customProviders = providers {
    session = AccountSession(
      transmitter: this.transmitter,
      helix: helix,
      twitchAuth: twitchAuth,
      accounts: accounts,
      account: twitchAccount,
      onApiAccessGained: () => unawaited(globals.refreshBadges()),
      onAccountChanged: _accountChanged,
      onTransmitterLeftChannels: () => joiner.transmitterLeftChannels(),
      onBlockedChanged: _rebuildMessagesFrom,
    );
    whispers = Whispers(this, storage: whisperRepository);

    // Set up the cache before constructing channels so each Channel can
    // hydrate its emotes/badges from disk in its constructor (channels are
    // created inside ClientChannels). Otherwise the cache is still null when
    // they hydrate and third-party emotes won't resolve until the network
    // refresh lands.
    cache = cacheRepository == null ? null : EmoteBadgeCache(repository: cacheRepository, providers: this.providers);
    globals = ChatGlobals(
      providers: this.providers,
      cache: cache,
      onBadgesChanged: _rebuildChannelMessages,
      onUserBadgeChanged: _rebuildMessagesFrom,
    );
    history = ChatHistory(
      recentMessages: recentMessages ?? RecentMessages(enabled: () => true, api: api),
      receiver: this.receiver,
      cache: cache,
      channels: () => channels.state,
      receive: receive,
    );

    channels = ClientChannels(
      this,
      repository: channelRepository,
    );

    // Prioritize the channel the user last had open so it lands in the first
    // (larger) JOIN burst and comes up before the rest of the list.
    final lastChannel = channelRepository.lastChannel;
    if (lastChannel != null && lastChannel.isNotEmpty) {
      channels.state.firstWhereOrNull((c) => c.name == lastChannel)?.joinPriority = true;
    }

    joiner = ChannelJoiner(receiver: this.receiver, transmitter: this.transmitter, channels: () => channels.state);

    this.receiver.onReceive = receive;
    this.transmitter.onReceive = receive;
    this.receiver.onStateChange = (connection, change) => joiner.receiverStateChanged(change);
    this.transmitter.onStateChange = (connection, change) => joiner.transmitterStateChanged(change);
    // The chat also arrives on the transmitter, as it's in every channel: drop it before it's logged or handled.
    this.transmitter.accepts = (message) => transmitterCommands.contains(message.command);

    // Reading needs no account: the receiver is anonymous from the start and stays so.
    this.receiver.add(ConnectionConnect(anonymousAccount()));

    if (twitchAccount != null) unawaited(connectAs(twitchAccount));

    unawaited(globals.refreshEmotes());
    unawaited(globals.refreshBadges());
    unawaited(globals.refreshUserBadges());
  }

  /// An account-less login: Twitch's anonymous `justinfan` nick with a random number and no token. Twitch lets it
  /// read any chat but not write.
  static TwitchAccount anonymousAccount([Random? random]) => TwitchAccount(
    tokenData: TokenData(
      clientId: null,
      login: 'justinfan${10000 + (random ?? Random()).nextInt(90000)}',
      scopes: const [],
      userId: null,
      expiresAt: null,
      accessToken: null,
    ),
    userData: null,
    cookies: null,
  );

  /// Stops the timers and closes both connections. Only tests need this: the app's client lives as long as the app.
  Future<void> close() async {
    session.close();
    globals.close();
    joiner.close();
    await _channelFocusRequests.close();
    await Future.wait([receiver.close(), transmitter.close()]);
  }

  // Messages resolve their badges when they're built, so history inserted
  // before the global badges arrived would otherwise never show them.
  void _rebuildChannelMessages() {
    for (final channel in [...channels.state, ...whispers.state]) {
      unawaited(channel.rebuildMessages());
    }
  }

  @override
  Future<void> connectAs(TwitchAccount twitchAccount) => session.connectAs(twitchAccount);

  /// Logs out, see [AccountSession.disconnect]. The anonymous receiver keeps reading the chat.
  @override
  void disconnect() => session.disconnect();

  // The active account changed (null: logged out). Shows this account's Twitch emotes from the last session right
  // away; the fresh list only arrives with GLOBALUSERSTATE after connecting. Also clears the previous account's emotes
  // when switching accounts.
  void _accountChanged(TwitchAccount? account) {
    globals.showCachedTwitchUserEmotes(account?.tokenData.userId);
    whispers.setAccount(account);
    eventSub.connect(account != null && whispers.hasScope ? account.tokenData : null);
  }

  void _rebuildMessagesFrom(String userId) {
    for (final channel in channels.state) {
      channel.rebuildMessagesFrom(userId);
    }
  }

  /// The chat color of [userId] as seen in any open channel, in IRC's `#RRGGBB` form. Whispers don't carry one.
  String? chatColorOf(String userId) {
    for (final channel in channels.state) {
      final message = channel.channelMessages.state.lastWhereOrNull(
        (m) => m is ChannelMessageChat && m.user.id == userId,
      ) as ChannelMessageChat?;
      final color = message?.message.tags['color'];
      if (color != null && color.isNotEmpty) return color;
    }
    return null;
  }

  /// Called every time the app returns to the foreground. Actively probes each
  /// socket (PING -> expect a fast reply); only the ones that don't answer are
  /// reconnected. A quick app-switch over a live connection answers instantly
  /// and costs nothing — no needless reconnect — while a socket killed by a
  /// lock/background fails the probe and recovers right away instead of waiting
  /// up to ~70s for the steady-state watchdog. When anything was actually dead,
  /// gap-fill the messages missed while away (parallel, dedup-safe).
  Future<void> onAppResumed() async {
    // Only the transmitter is logged in; the anonymous receiver is probed whatever happens to the login.
    final checkTransmitter = session.checkLoginOnResume();

    final results = await Future.wait([
      receiver.probeAlive(),
      if (checkTransmitter) transmitter.probeAlive(),
    ]);
    final receiverAlive = results[0];
    final transmitterAlive = !checkTransmitter || results[1];
    globals.bttvSocket.reconnect();
    eventSub.reconnect();
    if (!transmitterAlive) {
      ircLog('transmitter: no answer after resuming');
      transmitter.forceReconnect();
    }
    // Only the receiver carries the chat, so only a dead receiver missed messages.
    if (receiverAlive) return;
    ircLog('receiver: no answer after resuming');
    receiver.forceReconnect();

    // Visible (active/last) channel first so the chat being looked at fills
    // first; insertHistoryMessages dedups by id, so the later rejoin backfill
    // is a no-op for anything we pull in here.
    final viewed = channels.state.where((channel) => channel.recentMessagesEverFetched).toList()
      ..sort(ChannelJoiner.byJoinPriority);
    await history.refetch(viewed);
  }

  /// The commands the transmitter handles: its own handshake, what Twitch tells the account about itself, the echo
  /// of its own JOINs and the NOTICEs answering what it sent. Chat traffic (PRIVMSG, USERNOTICE, CLEARCHAT, CLEARMSG,
  /// ROOMSTATE, other users' JOIN and PART, …) also arrives on it but is ignored: the receiver shows it already.
  static const Set<String> transmitterCommands = {'001', 'GLOBALUSERSTATE', 'USERSTATE', 'JOIN', 'NOTICE'};

  /// Whether a JOIN [event] is the echo of the connection's own JOIN, the one registered as [nick].
  static bool isOwnJoin(irc.Message event, String nick) =>
      event.prefix?.split('!').first.toLowerCase() == nick.toLowerCase();

  /// How long two NOTICEs with the same text count as the same one, see [isDuplicateNotice].
  static const Duration noticeDuplicateWindow = Duration(seconds: 10);

  /// Whether [notice] was shown already among the [recent] messages of its channel, within [noticeDuplicateWindow]
  /// of [now]. Both connections are in every channel, so a NOTICE about the channel itself (e.g. slow mode turned on)
  /// can arrive on both; whichever comes first is shown.
  static bool isDuplicateNotice(List<ChannelMessage> recent, irc.Message notice, DateTime now) {
    final msgId = notice.tags['msg-id'];
    final text = notice.parameters.skip(1).join(':');
    for (var i = recent.length - 1; i >= 0 && i >= recent.length - 50; i--) {
      final message = recent[i];
      if (message is! ChannelMessageNotice) continue;
      if (now.difference(message.dateTime).abs() > noticeDuplicateWindow) continue;
      if (message.message.tags['msg-id'] == msgId && message.text == text) return true;
    }
    return false;
  }

  Future<void> receive(Connection connection, irc.Message event) async {
    if (connection == transmitter && !transmitterCommands.contains(event.command)) return;
    switch (event.command) {
      case '001':
        if (connection.state is ConnectionConnecting) {
          final stateTwitchAccount = (connection.state as ConnectionConnecting).twitchAccount;
          // Switch to connected immediately so channel joins can start, then
          // fetch the (paginated, slow) blocked-user list in the background and
          // fill it into the live state's mutable list.
          final connectedState = ConnectionConnected(stateTwitchAccount, nick: event.parameters.firstOrNull);
          // Joining starts from ChannelJoiner.receiverStateChanged once the state has switched.
          connection.add(ConnectionEstablished(connectedState));
          session.loadBlockedUsers(connectedState);
        }
        break;
      case 'GLOBALUSERSTATE':
        // Only the logged-in transmitter gets one; the account's color and emotes are its business.
        if (connection != transmitter) break;
        await _globalUserState(connection, event);
        break;
      case 'JOIN':
        final channel = _channelNamed(event.parameters[0]);
        if (channel == null) break;

        // Twitch echoes the JOIN with the nick the connection registered with, e.g. the receiver's justinfan nick.
        final connectionState = connection.state;
        if (connectionState is! ConnectionConnected || !isOwnJoin(event, connectionState.nick)) break;

        if (connection == transmitter) {
          joiner.transmitterJoined(channel.name);
          ircLog('transmitter: joined ${channel.name}');
          channel.transmitterJoin.joined();
          break;
        }

        if (channel.state is ChannelStateWithConnection) {
          joiner.receiverJoined(channel.name);
          ircLog('receiver: joined ${channel.name}');
          channel.add(ChannelConnect());
          history.joined(channel);
        }
        break;
      case 'USERNOTICE':
      case 'PRIVMSG':
        if (event.command == 'USERNOTICE') log(event.raw);

        final channel = _channelNamed(event.parameters[0]);
        if (channel == null) break;

        final ChannelMessage message = ChannelMessageChat(message: event, dateTime: _sentAt(event), channel: channel);

        for (final listener in listeners) {
          listener.onMessageReceived(message);
        }

        channel.channelMessages.add(message);
        break;
      case 'USERSTATE':
        // About the account in the channel, so only the transmitter's counts (the anonymous receiver isn't anyone).
        if (connection != transmitter) break;
        final channel = _channelNamed(event.parameters[0]);
        if (channel == null) break;
        channel.applyUserState(event);
        break;
      case 'ROOMSTATE':
        final channel = _channelNamed(event.parameters[0]);
        if (channel == null) break;

        channel.id = event.tags['room-id'];
        if (channel.id != null) globals.bttvSocket.join(channel.id!);

        // Paint cached history first using the emotes already hydrated from
        // disk at channel construction, so it shows immediately instead of
        // waiting on the network emote/badge refresh. refresh() then rebuilds
        // only if the network actually changes the emote/badge set.
        await history.insertCached(connection, channel);

        await channel.refresh();
        break;
      case 'CLEARCHAT':
        final channel = _channelNamed(event.parameters[0]);
        if (channel == null) break;
        channel.channelMessages.add(ChannelMessageBan(message: event, dateTime: _sentAt(event), channel: channel));
        break;
      case 'NOTICE':
        // The handshake rejection arrives as `NOTICE * :Login authentication
        // failed` — target `*`, so the channel lookup below finds nothing and
        // used to drop it on the floor while the socket closed and the backoff
        // retried the same dead token forever. Catch it here instead.
        if (session.handleAuthFailureNotice(connection, event)) break;

        final channel = _channelNamed(event.parameters[0]);
        if (channel == null) break;

        // Both connections join the channel, so both are told it's suspended; the receiver's channel state shows it.
        if (event.tags['msg-id'] == 'msg_channel_suspended') {
          if (connection == transmitter) break;
          channel.add(ChannelSuspend());
        }

        // NOTICEs answering a message (rate limit, banned, slow mode, …) only reach the transmitter. One about the
        // channel can reach both connections: show it once.
        final now = DateTime.now();
        if (isDuplicateNotice(channel.channelMessages.state, event, now)) break;

        channel.channelMessages.add(ChannelMessageNotice(message: event, dateTime: _sentAt(event), channel: channel));
        break;
      default:
        log(event.raw);
        break;
    }
  }

  Channel? _channelNamed(String name) => channels.state.firstWhereOrNull((channel) => channel.name == name);

  /// When Twitch says [event] was sent, or now if it doesn't say.
  static DateTime _sentAt(irc.Message event) => DateTime.fromMillisecondsSinceEpoch(
    int.tryParse(event.tags['tmi-sent-ts'] ?? 'null') ?? DateTime.now().millisecondsSinceEpoch,
  );

  /// The transmitter's GLOBALUSERSTATE: the account's chat color and the Twitch emotes it can use everywhere.
  Future<void> _globalUserState(Connection connection, irc.Message event) async {
    try {
      if (connection.state is ConnectionStateWithCredentials) {
        final stateTwitchAccount = (connection.state as ConnectionStateWithCredentials).twitchAccount;
        session.ownColor = event.tags['color'];
        // Without a Twitch provider (tests) the emotes would have no provider to belong to: don't ask for them.
        final twitch = providers.firstWhereOrNull((provider) => provider.name == 'Twitch');
        if (twitch == null) return;
        final emotes = await helix
            .forToken(stateTwitchAccount.tokenData)
            .emoteSets(event.tags['emote-sets']?.split(',') ?? []);
        // Every account has at least the global Twitch emotes, so an empty
        // result means the request failed: keep the cached list instead.
        if (emotes.isNotEmpty) {
          final userEmotes = [
            for (final emote in emotes)
              Emote(
                id: emote.id,
                mipmap: emote.images.values.toList(),
                name: emote.name,
                provider: twitch,
              ),
          ];
          globals.setTwitchUserEmotes(stateTwitchAccount.tokenData.userId, userEmotes);
        }
      }
    } catch (e) {
      log('Couldn\'t get twitch user emotes: $e');
    }
  }
}
