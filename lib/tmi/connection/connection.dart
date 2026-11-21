import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/twitch_account.dart';
import '../../irc/message.dart' as irc;
import '../irc_log.dart';
import '../tmi_exception.dart';
import 'connection_event.dart';
import 'connection_state.dart';

class Connection extends Bloc<ConnectionEvent, ConnectionState> {
  WebSocketChannel? channel;
  StreamSubscription<dynamic>? subscription;
  void Function(Connection connection, ConnectionEvent event)? onEventTrigger;
  void Function(Connection connection, Change<ConnectionState> change)? onStateChange;
  void Function(Connection connection, irc.Message event)? onReceive;
  TwitchAccount? get twitchAccount =>
      (state is ConnectionStateWithCredentials) ? (state as ConnectionStateWithCredentials).twitchAccount : null;

  @override
  void onEvent(ConnectionEvent event) {
    onEventTrigger?.call(this, event);
    super.onEvent(event);
  }

  @override
  void onChange(Change<ConnectionState> change) {
    ircLog(
      '$name: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType} as ${describe(change.nextState)}',
    );
    onStateChange?.call(this, change);
    super.onChange(change);
  }

  /// Opens the IRC socket. Replaceable so tests can connect to a fake.
  final WebSocketChannel Function(Uri uri) _openSocket;

  static WebSocketChannel _openIoSocket(Uri uri) => IOWebSocketChannel.connect(uri);

  /// What the `[irc]` diagnostics call this connection, e.g. `receiver` or `transmitter`.
  final String name;

  /// The login a [state] is for, or `anonymous` for a `justinfan` connection, for the `[irc]` diagnostics.
  static String describe(ConnectionState state) => switch (state) {
    ConnectionStateWithCredentials(:final twitchAccount) =>
      twitchAccount.tokenData.accessToken == null ? 'anonymous' : twitchAccount.tokenData.login,
    _ => 'nobody',
  };

  /// Whether to request `twitch.tv/membership`, which adds every other user's JOIN and PART. The own JOIN is echoed
  /// without it too.
  final bool membership;

  /// Which received lines are handed to [onReceive]; null for all of them.
  bool Function(irc.Message message)? accepts;

  Connection({WebSocketChannel Function(Uri uri)? openSocket, this.name = 'connection', this.membership = true})
    : _openSocket = openSocket ?? _openIoSocket,
      super(ConnectionDisconnected()) {
    on<ConnectionConnect>((event, emit) async {
      _lastAccount = event.twitchAccount;
      // A connect with (presumably) fresh credentials clears the auth lock so
      // the watchdog and the backoff can do their job again.
      _credentialsRejected = false;
      emit(ConnectionConnecting(event.twitchAccount));
      await connect(
        nick: event.twitchAccount.tokenData.login,
        pass: event.twitchAccount.tokenData.accessToken != null
            ? 'oauth:${event.twitchAccount.tokenData.accessToken}'
            : null,
      );
    });

    on<ConnectionEstablished>((event, emit) => emit(event.state));

    on<ConnectionDisconnect>((event, emit) async {
      // Logging out: drop the socket and forget the account so no reconnect
      // path (backoff, watchdog, app resume) brings it back. Not close(): that
      // would end the bloc, and a later login could never connect again.
      _lastAccount = null;
      _credentialsRejected = false;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _connectStartedAt = null;
      await cancel();
      emit(ConnectionDisconnected());
    });

    on<ConnectionReconnect>((event, emit) async {
      // Never reconnect with credentials Twitch already refused — that is the
      // endless silent retry loop that made an expired login look like a dead
      // chat. Only an explicit ConnectionConnect (i.e. after re-login) resumes.
      if (_credentialsRejected && event.twitchAccount == null) return;
      // Fall back to the last account we connected with so a reconnect still
      // fires even from ConnectionDisconnected (the old guard silently dropped
      // it, leaving the chat stuck forever).
      final account =
          event.twitchAccount ??
          _lastAccount ??
          (state is ConnectionStateWithCredentials ? (state as ConnectionStateWithCredentials).twitchAccount : null);
      if (account == null) return;
      ircLog('$name: reconnecting (${event.reason})');
      add(ConnectionConnect(account));
    });

    on<ConnectionCredentialsRejected>((event, emit) async {
      _credentialsRejected = true;
      _lastAccount = event.twitchAccount;
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _connectStartedAt = null;
      // Abandon a connect() that is still tearing down the previous socket.
      _connectGeneration++;
      await cancel();
      emit(ConnectionInvalidCredentials(event.twitchAccount));
    });

    _startWatchdog();
  }

  Future<void> connect({
    String? nick,
    String? pass,
  }) async {
    // Kill any pending backoff reconnect. While the app is suspended iOS freezes
    // the backoff timer; on resume it would thaw and fire a second reconnect
    // that tears down the one we are establishing here, restarting the
    // handshake and making coming back from background feel slow.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectStartedAt = DateTime.now();
    _lastInbound = null;
    _lastPingSentAt = null;
    final generation = ++_connectGeneration;
    await cancel();
    // Bloc runs the events of one handler concurrently, so a second connect()
    // (e.g. the forced reconnect on app resume racing the watchdog's) can start
    // while this one is still awaiting cancel(). Only the newest one may open a
    // socket; if this one opened its socket too, it would overwrite the other's
    // channel/subscription and leave that socket open but untracked, and its
    // later onDone would tear down the healthy connection with a reconnect.
    if (generation != _connectGeneration || isClosed) return;
    final socket = _openSocket(Uri.parse('wss://irc-ws.chat.twitch.tv:443'));
    channel = socket;
    // A failed connect (e.g. no network) completes `ready` with the same error
    // the stream reports. The stream's onError/onDone below does the
    // reconnecting; unhandled, `ready` would only add an uncaught exception.
    unawaited(socket.ready.catchError((Object error) => ircLog('$name: could not connect: $error')));

    // A failing socket reports onError and then onDone; it counts as one failed attempt, so only the first of them
    // schedules the reconnect. Otherwise each failure would step the backoff twice (first retry after 2s, not 1s).
    var reconnectScheduled = false;
    void socketEnded() {
      if (reconnectScheduled || generation != _connectGeneration) return;
      reconnectScheduled = true;
      _scheduleReconnect();
    }

    subscription = socket.stream.listen(
      (event) async {
        for (final singleEvent
            in (event as String)
                .trim()
                .split('\r\n')
                .where((String singleEvent) => singleEvent.isNotEmpty)
                .map((String singleEvent) => singleEvent.trim())) {
          final message = irc.Message.fromEvent(singleEvent);
          unawaited(receive(message));
        }
      },
      onDone: socketEnded,
      onError: (Object error) => socketEnded(),
      // cancelOnError: true,
    );

    unawaited(send('CAP REQ :twitch.tv/tags twitch.tv/commands${membership ? ' twitch.tv/membership' : ''}'));
    if (pass != null) unawaited(send('PASS $pass'));
    unawaited(send('NICK ${nick ?? 'justinfan6969'}'));
  }

  Future<void> send(String message) async {
    try {
      if (channel == null) throw const TmiException('not connected');
      channel?.sink.add(message);
    } catch (e) {
      // Not the line itself: PASS carries the token.
      ircLog('$name: could not send: $e');
    }
  }

  // Reconnect backoff: 1, 2, 4, 8, 16s. Reset as soon as any line is received
  // (the socket is alive again). The old 4s fixed delay made coming back from a
  // long background feel slow; the first retry now fires after ~1s. Held in a
  // cancellable timer so connect() (e.g. the forced reconnect on app resume)
  // can pre-empt a frozen/pending backoff instead of racing it.
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// Bumped by every connect() and by everything that abandons the connection,
  /// so a connect() that was overtaken while awaiting cancel() gives up.
  int _connectGeneration = 0;

  /// Set once the token was refused; blocks the automatic retry paths (socket
  /// close, handshake timeout, liveness watchdog) until a re-login arrives.
  bool _credentialsRejected = false;

  bool get credentialsRejected => _credentialsRejected;

  void _scheduleReconnect() {
    if (_credentialsRejected) return;
    _reconnectTimer?.cancel();
    final seconds = (1 << _reconnectAttempts).clamp(1, 16);
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () => add(ConnectionReconnect(reason: 'socket closed')));
  }

  // Liveness watchdog. Mobile sockets routinely go half-open (lock screen /
  // pocket suspend, Wi-Fi<->cellular handoff, NAT timeout): the TCP is dead but
  // no FIN/RST arrives, so onDone/onError never fire and the reconnect backoff
  // never starts. Likewise a connect() after wake can open a socket that never
  // receives 001 and never closes, stranding the state at ConnectionConnecting
  // with every channel parted to ChannelDisconnected. This periodic check is
  // the catch-all that detects both and forces a reconnect — and because iOS
  // freezes timers while suspended, it also fires within ~5s of any wake.
  TwitchAccount? _lastAccount;
  DateTime? _connectStartedAt;
  DateTime? _lastInbound;
  DateTime? _lastPingSentAt;
  Timer? _watchdog;

  static const Duration _handshakeTimeout = Duration(seconds: 8);
  static const Duration _inboundTimeout = Duration(seconds: 70);
  static const Duration _pingInterval = Duration(seconds: 60);

  bool get isConnected => state is ConnectionConnected;

  /// Actively check the socket is alive: send a PING and wait briefly for any
  /// inbound line (Twitch answers with PONG almost immediately). This avoids
  /// the false "stale" verdict that silence alone gives — a quiet channel can
  /// legitimately receive nothing for a minute, so absence of traffic is not
  /// proof the socket is dead. A genuinely dead socket produces no reply and we
  /// report not-alive so the caller can reconnect.
  Future<bool> probeAlive({Duration timeout = const Duration(seconds: 3)}) async {
    if (state is! ConnectionConnected) return false;
    final before = _lastInbound;
    unawaited(send('PING :tmi.twitch.tv'));
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (_lastInbound != before) return true;
    }
    return false;
  }

  void forceReconnect() => add(ConnectionReconnect(reason: 'forced'));

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) => _checkLiveness());
  }

  void _checkLiveness() {
    if (isClosed) return;
    if (_credentialsRejected) return;
    final now = DateTime.now();
    if (state is ConnectionConnecting) {
      final started = _connectStartedAt;
      if (started != null && now.difference(started) > _handshakeTimeout) {
        add(ConnectionReconnect(reason: 'handshake timed out'));
      }
      return;
    }
    if (state is ConnectionConnected) {
      final last = _lastInbound ?? _connectStartedAt;
      if (last == null) return;
      if (now.difference(last) > _inboundTimeout) {
        add(ConnectionReconnect(reason: 'nothing received for ${_inboundTimeout.inSeconds}s'));
        return;
      }
      // Proactively PING so a dead socket surfaces fast (no inbound -> timeout)
      // instead of waiting up to ~5min for Twitch's own keepalive.
      final lastPing = _lastPingSentAt;
      if (now.difference(last) > _pingInterval && (lastPing == null || now.difference(lastPing) > _pingInterval)) {
        _lastPingSentAt = now;
        unawaited(send('PING :tmi.twitch.tv'));
      }
    }
  }

  Future<void> receive(irc.Message event) async {
    try {
      _reconnectAttempts = 0;
      _lastInbound = DateTime.now();
      // Lines this connection doesn't use are dropped before they're handled; it still answers Twitch's PING.
      if (event.command != 'PING' && accepts?.call(event) == false) return;
      onReceive?.call(this, event);
      if (event.command == 'PING') {
        await send('PONG :${event.parameters.join(' ')}');
      }
    } catch (e) {
      ircLog('$name: could not handle ${event.command}: $e');
    }
  }

  Future<void> cancel() async {
    final oldSubscription = subscription;
    final oldChannel = channel;
    subscription = null;
    channel = null;
    try {
      await oldSubscription?.cancel();
    } catch (_) {}
    // Do NOT await the close: a dead/half-open socket (lock-screen suspend,
    // network handoff) can make sink.close() hang forever. An awaited close
    // here would keep connect() from ever opening the new socket, leaving the
    // chat stuck on ChannelDisconnected. Fire-and-forget instead.
    if (oldChannel != null) unawaited(oldChannel.sink.close().catchError((_) {}));
  }

  @override
  Future<void> close() {
    _watchdog?.cancel();
    _reconnectTimer?.cancel();
    _connectGeneration++;
    // Stop delivering socket lines to a closed bloc.
    unawaited(subscription?.cancel());
    return super.close();
  }
}
