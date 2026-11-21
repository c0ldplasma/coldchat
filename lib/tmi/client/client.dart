import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random, min;

import 'package:bloc/bloc.dart';
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
import '../../api/twitch/twitch.dart';
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
import 'chat_globals.dart';
import 'chat_history.dart';
import 'client_channels.dart';
import 'client_listener.dart';
import 'join_scheduler.dart';

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

  // The account whose token is used for Twitch API requests such as badges.
  TwitchAccount? _apiAccount;

  /// The token for Helix requests, or null while browsing anonymously.
  TokenData? get apiTokenData => _apiAccount?.tokenData.accessToken == null ? null : _apiAccount!.tokenData;

  /// The app's HTTP client, shared by every API below.
  final ApiClient api;

  /// Helix as the account in [apiTokenData]. [HelixApi.forToken] sends as another one.
  late final HelixApi helix = HelixApi(api, () => apiTokenData);

  late final TwitchAuthApi twitchAuth = TwitchAuthApi(api);

  /// The connected, logged-in account, which is the one whose Twitch block list hides messages.
  ConnectionConnected? get _blockingState {
    final state = transmitter.state;
    return state is ConnectionConnected && state.twitchAccount.tokenData.accessToken != null ? state : null;
  }

  /// The id of the account that can block users, or null while anonymous or disconnected.
  String? get blockingUserId => _blockingState?.twitchAccount.tokenData.userId;

  bool isBlocked(String userId) => _blockingState?.blockedUserIds.contains(userId) ?? false;

  /// Blocks or unblocks [userId] on Twitch and re-renders their messages in every channel.
  Future<void> setBlocked(String userId, bool blocked) async {
    final state = _blockingState;
    if (state == null) throw Exception('Not logged in');
    if (blocked) {
      await helix.forToken(state.twitchAccount.tokenData).blockUser(userId);
      if (!state.blockedUserIds.contains(userId)) state.blockedUserIds.add(userId);
    } else {
      await helix.forToken(state.twitchAccount.tokenData).unblockUser(userId);
      state.blockedUserIds.remove(userId);
    }
    _rebuildMessagesFrom(userId);
  }

  /// The own login that mentions highlight, or null while logged out.
  String? get ownLogin {
    final account = transmitter.twitchAccount;
    return account?.tokenData.accessToken == null ? null : account!.tokenData.login;
  }

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

  /// The logged-in user's chat color, from GLOBALUSERSTATE, for the whispers they send.
  String? ownColor;
  EmoteBadgeCache? cache;

  List<ClientListener> listeners = [];

  /// The global emotes and badges, the account's Twitch emotes and the BetterTTV Pro badges.
  late final ChatGlobals globals;

  /// Where a refreshed expiry of the active account is saved. Null in tests, then nothing is saved.
  final AccountRepository? accounts;

  /// The message and user triggers that highlight or block messages. Null in tests, then there are none.
  final TriggerRepository? triggers;

  /// The chat history of the channels, from the recent-messages service and the cache.
  late final ChatHistory history;

  final List<Timer> _timers = [];

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
    this.accounts,
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
    whispers = Whispers(this, storage: whisperRepository);

    // Set up the cache before constructing channels so each Channel can
    // hydrate its emotes/badges from disk in its constructor (channels are
    // created inside ClientChannels). Otherwise the cache is still null when
    // they hydrate and third-party emotes won't resolve until the network
    // refresh lands.
    if (cacheRepository != null) {
      cache = EmoteBadgeCache(repository: cacheRepository, providers: this.providers);
    }
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

    // Drain the join queue on a timer as a steady-state fallback, but also
    // trigger an immediate pass as soon as the connection is established
    // (see the _joinPass call in stateChange) so we don't idle up to 2s
    // waiting for the first tick.
    _timers.add(Timer.periodic(const Duration(seconds: 2), (timer) => _joinPass()));

    // Twitch requires apps to validate a user token at startup and then hourly while running
    // (https://dev.twitch.tv/docs/authentication/validate-tokens/), so a login revoked on Twitch's side is noticed
    // even when the app stays open. Startup, every connect and every return to the foreground validate already.
    _timers.add(
      Timer.periodic(const Duration(hours: 1), (timer) {
        final account = _apiAccount;
        if (account != null) unawaited(validateCredentials(account));
      }),
    );

    this.receiver.onReceive = receive;
    this.transmitter.onReceive = receive;
    this.receiver.onStateChange = stateChange;
    this.transmitter.onStateChange = _transmitterStateChange;
    // The chat also arrives on the transmitter, as it's in every channel: drop it before it's logged or handled.
    this.transmitter.accepts = (message) => transmitterCommands.contains(message.command);

    // Reading needs no account: the receiver is anonymous from the start and stays so.
    this.receiver.add(ConnectionConnect(anonymousAccount()));

    _apiAccount = twitchAccount;
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
    for (final timer in _timers) {
      timer.cancel();
    }
    globals.close();
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

  // Twitch IRC allows 20 JOINs per 10 seconds for normal users; _joins keeps every pass within that (with a margin)
  // over a rolling window. The first pass after connecting may join a larger burst so the channels the user cares
  // about come up quickly; steady-state ticks stay conservative. The receiver and the transmitter each have their
  // own scheduler: the limit is per user, and the anonymous receiver isn't the account.
  bool _firstJoinPass = true;
  final JoinScheduler _joins = JoinScheduler();
  bool _firstTransmitterJoinPass = true;
  final JoinScheduler _transmitterJoins = JoinScheduler();

  /// Sends the JOINs that are due now instead of waiting for the next tick, e.g. after adding a channel. They still
  /// go through the rate limit.
  void joinPending() => _joinPass();

  // Channels the user has explicitly requested (active chat view) or last had
  // open sort first, so the channel actually being looked at is handled first.
  static int _byJoinPriority(Channel a, Channel b) => a.joinPriority == b.joinPriority ? 0 : (a.joinPriority ? -1 : 1);

  void _joinPass() {
    _receiverJoinPass();
    _transmitterJoinPass();
  }

  void _receiverJoinPass() {
    if (receiver.state is! ConnectionConnected) return;
    // A JOIN that never got an echo (dropped by Twitch, or the channel doesn't exist) would leave the channel
    // connecting forever: queue it again, a limited number of times.
    for (final name in _joins.takeTimedOut()) {
      final channel = channels.state.firstWhereOrNull((channel) => channel.name == name);
      if (channel == null || channel.state is! ChannelConnecting) continue;
      final retry = _joins.canRetry(name);
      ircLog('receiver: JOIN $name timed out, ${retry ? 'retrying' : 'giving up until the next reconnect'}');
      if (retry) channel.add(ChannelPart());
    }
    final disconnected = channels.state.where((channel) => channel.state is ChannelDisconnected).toList();
    if (disconnected.isEmpty) return;
    final batchSize = min(_firstJoinPass ? 12 : 4, _joins.available);
    if (batchSize <= 0) return;
    disconnected.sort(_byJoinPriority);
    _firstJoinPass = false;
    final channelsToJoin = disconnected.take(batchSize).toList();
    for (final channel in channelsToJoin) {
      channel.add(ChannelJoin(receiver, transmitter));
    }
    _joins.sent(channelsToJoin.map((e) => e.name));
    final names = channelsToJoin.map((e) => e.name).join(',');
    ircLog('receiver: JOIN $names');
    unawaited(receiver.send('JOIN $names'));
  }

  /// Joins the channels on the transmitter too, so it gets the account's USERSTATE there. Same rate limit and retries
  /// as the receiver, with its own [JoinScheduler] because the limit is per account.
  void _transmitterJoinPass() {
    if (transmitter.state is! ConnectionConnected) return;
    for (final name in _transmitterJoins.takeTimedOut()) {
      final retry = _transmitterJoins.canRetry(name);
      ircLog('transmitter: JOIN $name timed out, ${retry ? 'retrying' : 'giving up until the next reconnect'}');
    }
    final unjoined = channels.state
        .where(
          (channel) =>
              !channel.transmitterJoin.state &&
              !_transmitterJoins.isPending(channel.name) &&
              _transmitterJoins.canRetry(channel.name),
        )
        .toList();
    if (unjoined.isEmpty) return;
    final batchSize = min(_firstTransmitterJoinPass ? 12 : 4, _transmitterJoins.available);
    if (batchSize <= 0) return;
    unjoined.sort(_byJoinPriority);
    _firstTransmitterJoinPass = false;
    final channelsToJoin = unjoined.take(batchSize).map((e) => e.name).toList();
    _transmitterJoins.sent(channelsToJoin);
    final names = channelsToJoin.join(',');
    ircLog('transmitter: JOIN $names');
    unawaited(transmitter.send('JOIN $names'));
  }

  /// The transmitter left every channel: it reconnected, switched accounts or logged out. Forgets the own user's
  /// state in each channel (e.g. moderator status of the previous account) until the next JOIN and USERSTATE.
  void _transmitterLeftChannels() {
    for (final channel in channels.state) {
      channel.transmitterParted();
    }
    _firstTransmitterJoinPass = true;
    _transmitterJoins.reset();
  }

  void _transmitterStateChange(Connection connection, Change<ConnectionState> change) {
    _transmitterLeftChannels();
    // Bloc calls onChange before it sets the new state, so the pass has to wait until the state is ConnectionConnected.
    if (change.nextState is ConnectionConnected) scheduleMicrotask(_transmitterJoinPass);
  }

  /// Called every time the app returns to the foreground. Actively probes each
  /// socket (PING -> expect a fast reply); only the ones that don't answer are
  /// reconnected. A quick app-switch over a live connection answers instantly
  /// and costs nothing — no needless reconnect — while a socket killed by a
  /// lock/background fails the probe and recovers right away instead of waiting
  /// up to ~70s for the steady-state watchdog. When anything was actually dead,
  /// gap-fill the messages missed while away (parallel, dedup-safe).
  Future<void> onAppResumed() async {
    // A token can expire while the app sits in the background for days, so
    // check before probing: reconnecting with it is pointless and the socket
    // failure would be indistinguishable from a network hiccup.
    // Only the transmitter is logged in; the anonymous receiver is probed whatever happens to the login.
    final account = transmitter.twitchAccount;
    var checkTransmitter = false;
    if (account != null && account.tokenData.accessToken != null) {
      if (account.tokenData.isExpired) {
        _rejectCredentials(account);
      } else if (!transmitter.credentialsRejected) {
        checkTransmitter = true;
        unawaited(validateCredentials(account));
      }
    }

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
    final viewed = channels.state.where((channel) => channel.recentMessagesEverFetched).toList()..sort(_byJoinPriority);
    await history.refetch(viewed);
  }

  /// Twitch refuses a bad token with an untagged NOTICE whose text we have to
  /// match; there is no msg-id on these. Only ever sent with target `*` (i.e.
  /// before we are authenticated), which keeps this from matching channel chat.
  static bool _isAuthFailureNotice(irc.Message event) {
    if (event.parameters.isEmpty || event.parameters.first != '*') return false;
    final text = event.parameters.length > 1 ? event.parameters.last.toLowerCase() : '';
    return text.contains('login authentication failed') ||
        text.contains('login unsuccessful') ||
        text.contains('improperly formatted auth');
  }

  /// Locks the transmitter until a new login, because Twitch refused [twitchAccount]'s token. The anonymous receiver
  /// has no token and keeps reading. Ignored when [twitchAccount] isn't the active account anymore (e.g. a check
  /// that was still running while switching accounts), so it can't lock out the account that is active now.
  void _rejectCredentials(TwitchAccount twitchAccount) {
    final active = _apiAccount;
    if (active == null || active.tokenData.hash != twitchAccount.tokenData.hash) return;
    ircLog('transmitter: login of ${twitchAccount.tokenData.login} rejected');
    transmitter.add(ConnectionCredentialsRejected(twitchAccount));
  }

  /// Ask Twitch whether the stored token is still good, and keep [TokenData]
  /// honest about it. On a 401 the login is dead — reject it so the UI can say
  /// so instead of letting the reconnect loop churn silently. Network failures
  /// are ignored: being offline is not proof the token expired.
  Future<void> validateCredentials(TwitchAccount twitchAccount) async {
    final accessToken = twitchAccount.tokenData.accessToken;
    if (accessToken == null) return; // anonymous
    if (twitchAccount.tokenData.isExpired) {
      _rejectCredentials(twitchAccount);
      return;
    }

    try {
      final fresh = await twitchAuth.validateToken(accessToken);
      // The stored expiresAt is a snapshot from login time and is never touched
      // afterwards; refresh it so the account modal and the local expiry check
      // reflect reality.
      twitchAccount.tokenData.expiresAt = fresh.expiresAt;
      twitchAccount.tokenData.scopes = fresh.scopes;
      try {
        await accounts?.update(twitchAccount);
      } catch (_) {
        // Not attached to a box (e.g. constructed in-memory) — nothing to persist.
      }
      if (twitchAccount.tokenData.isExpired) _rejectCredentials(twitchAccount);
    } on TwitchTokenInvalidException {
      _rejectCredentials(twitchAccount);
    } catch (e) {
      log('Couldn\'t validate the Twitch token: $e');
    }
  }

  @override
  Future<void> connectAs(TwitchAccount twitchAccount) async {
    // Don't even open the socket with a token we already know is dead: the
    // handshake would fail with no feedback.
    if (twitchAccount.tokenData.accessToken != null && twitchAccount.tokenData.isExpired) {
      _apiAccount = twitchAccount;
      _transmitterLeftChannels();
      _rejectCredentials(twitchAccount);
      return;
    }

    // Show this account's Twitch emotes from the last session right away; the
    // fresh list only arrives with GLOBALUSERSTATE after connecting. Also
    // clears the previous account's emotes when switching accounts.
    // Twitch badges need a token, so a first login after browsing anonymously
    // has to load them now.
    final gainedApiAccess = _apiAccount?.tokenData.accessToken == null && twitchAccount.tokenData.accessToken != null;
    _apiAccount = twitchAccount;
    if (gainedApiAccess) unawaited(globals.refreshBadges());
    ircLog('transmitter: switching to ${twitchAccount.tokenData.login}');

    globals.showCachedTwitchUserEmotes(twitchAccount.tokenData.userId);

    whispers.setAccount(twitchAccount);
    ownColor = null;
    eventSub.connect(whispers.hasScope ? twitchAccount.tokenData : null);

    // Only the transmitter changes account. The receiver keeps reading, so the chat stays live and nothing is parted,
    // rejoined or fetched again; the composer waits until the transmitter has joined the channel (Channel.canSend).
    _transmitterLeftChannels();
    transmitter.add(ConnectionConnect(twitchAccount));
    // Confirm with Twitch in the background — the local expiry check only
    // catches tokens we know about; a manually revoked one still needs the API.
    unawaited(validateCredentials(twitchAccount));
  }

  /// Logs out: closes the transmitter and stops whispers until [connectAs] is called again. The anonymous receiver
  /// keeps reading the chat.
  @override
  void disconnect() {
    ircLog('transmitter: logging out');
    _apiAccount = null;
    globals.showCachedTwitchUserEmotes(null);
    whispers.setAccount(null);
    ownColor = null;
    eventSub.connect(null);
    _transmitterLeftChannels();
    transmitter.add(ConnectionDisconnect());
  }

  /// The receiver's state changed: every channel has to be joined again (with fresh history), see [ChannelPart].
  Future<void> stateChange(Connection connection, Change<ConnectionState> change) async {
    for (final channel in channels.state) {
      channel.add(ChannelPart());
    }
    // On (re)connect, allow another larger join burst (still within the rate limit) and give every channel fresh
    // JOIN attempts.
    _firstJoinPass = true;
    _joins.reset();
    // Bloc calls onChange before it sets the new state, so the pass has to wait until the state is ConnectionConnected
    // (it used to return right away and leave the first JOINs to the next 2 s tick).
    if (change.nextState is ConnectionConnected) scheduleMicrotask(_receiverJoinPass);
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
          // Joining starts from stateChange once the state has switched.
          connection.add(ConnectionEstablished(connectedState));
          if (stateTwitchAccount.tokenData.accessToken != null) {
            unawaited(
              helix
                  .forToken(stateTwitchAccount.tokenData)
                  .blockedUsers()
                  .then(connectedState.blockedUserIds.addAll)
                  .catchError((Object e) => log('Couldn\'t get the blocked users: $e')),
            );
          }
        }
        break;
      case 'GLOBALUSERSTATE':
        // Only the logged-in transmitter gets one; the account's color and emotes are its business.
        if (connection != transmitter) break;
        try {
          if (connection.state is ConnectionStateWithCredentials) {
            final stateTwitchAccount = (connection.state as ConnectionStateWithCredentials).twitchAccount;
            ownColor = event.tags['color'];
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
                    provider: providers.firstWhere((element) => element.name == 'Twitch'),
                  ),
              ];
              globals.setTwitchUserEmotes(stateTwitchAccount.tokenData.userId, userEmotes);
            }
          }
        } catch (e) {
          log('Couldn\'t get twitch user emotes');
        }
        break;
      case 'JOIN':
        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        // Twitch echoes the JOIN with the nick the connection registered with, e.g. the receiver's justinfan nick.
        final connectionState = connection.state;
        if (connectionState is! ConnectionConnected || !isOwnJoin(event, connectionState.nick)) break;

        if (connection == transmitter) {
          _transmitterJoins.acknowledged(channel.name);
          ircLog('transmitter: joined ${channel.name}');
          channel.transmitterJoin.joined();
          break;
        }

        if (channel.state is ChannelStateWithConnection) {
          _joins.acknowledged(channel.name);
          ircLog('receiver: joined ${channel.name}');
          channel.add(ChannelConnect());
          history.joined(channel);
        }
        break;
      case 'USERNOTICE':
      case 'PRIVMSG':
        if (event.command == 'USERNOTICE') log(event.raw);

        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        final ChannelMessage message = ChannelMessageChat(
          message: event,
          dateTime: DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(event.tags['tmi-sent-ts'] ?? 'null') ?? DateTime.now().millisecondsSinceEpoch,
          ),
          channel: channel,
        );

        for (final listener in listeners) {
          listener.onMessageReceived(message);
        }

        channel.channelMessages.add(message);
        break;
      case 'USERSTATE':
        // About the account in the channel, so only the transmitter's counts (the anonymous receiver isn't anyone).
        if (connection != transmitter) break;
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == event.parameters[0]);
        if (channel == null) break;
        channel.applyUserState(event);
        break;
      case 'ROOMSTATE':
        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

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
        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        channel.channelMessages.add(
          ChannelMessageBan(
            message: event,
            dateTime: DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(event.tags['tmi-sent-ts'] ?? 'null') ?? DateTime.now().millisecondsSinceEpoch,
            ),
            channel: channel,
          ),
        );
        break;
      case 'NOTICE':
        // The handshake rejection arrives as `NOTICE * :Login authentication
        // failed` — target `*`, so the channel lookup below finds nothing and
        // used to drop it on the floor while the socket closed and the backoff
        // retried the same dead token forever. Catch it here instead.
        if (_isAuthFailureNotice(event)) {
          // Only the transmitter logs in; the receiver has no token to refuse.
          final account = connection.twitchAccount;
          if (connection == transmitter && account != null) _rejectCredentials(account);
          break;
        }

        final channelName = event.parameters[0];
        final channel = channels.state.firstWhereOrNull((channel) => channel.name == channelName);
        if (channel == null) {
          break;
        }

        // Both connections join the channel, so both are told it's suspended; the receiver's channel state shows it.
        if (event.tags['msg-id'] == 'msg_channel_suspended') {
          if (connection == transmitter) break;
          channel.add(ChannelSuspend());
        }

        // NOTICEs answering a message (rate limit, banned, slow mode, …) only reach the transmitter. One about the
        // channel can reach both connections: show it once.
        final now = DateTime.now();
        if (isDuplicateNotice(channel.channelMessages.state, event, now)) break;

        channel.channelMessages.add(
          ChannelMessageNotice(
            message: event,
            dateTime: DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(event.tags['tmi-sent-ts'] ?? 'null') ?? DateTime.now().millisecondsSinceEpoch,
            ),
            channel: channel,
          ),
        );
        break;
      default:
        log(event.raw);
        break;
    }
  }
}
