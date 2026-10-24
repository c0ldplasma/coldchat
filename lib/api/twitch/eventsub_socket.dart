import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/io.dart';

import '/data/twitch/token_data.dart';
import 'twitch.dart';

/// A whisper the logged-in account received (EventSub `user.whisper.message`).
class ReceivedWhisper {
  final String id;
  final String fromUserId;
  final String fromLogin;
  final String fromDisplayName;
  final String text;

  ReceivedWhisper({
    required this.id,
    required this.fromUserId,
    required this.fromLogin,
    required this.fromDisplayName,
    required this.text,
  });
}

/// Twitch EventSub over a WebSocket, subscribed to the account's incoming whispers. Twitch has dropped every
/// other way to receive them (PubSub is gone, IRC whispers are undocumented), and there is no API for whisper
/// history, so anything sent while this socket is down is lost.
class EventSubSocket {
  final void Function(ReceivedWhisper whisper) onWhisper;

  /// Called when Twitch refuses the subscription, e.g. because the token lacks `user:manage:whispers`.
  final void Function(TwitchRequestException error)? onSubscribeFailed;

  EventSubSocket({required this.onWhisper, this.onSubscribeFailed});

  static const String _url = 'wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30';

  TokenData? _tokenData;
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  // The connection that Twitch asked us to leave (session_reconnect). It keeps delivering events until the
  // new one sends its welcome, which carries the same subscriptions.
  IOWebSocketChannel? _previousChannel;
  StreamSubscription<dynamic>? _previousSubscription;
  bool _migrating = false;

  Timer? _keepaliveTimer;
  Duration _keepalive = const Duration(seconds: 30);
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // Twitch may deliver a notification more than once.
  final List<String> _seenMessageIds = [];

  /// Starts listening for [tokenData]'s whispers, or stops when it is null (anonymous).
  void connect(TokenData? tokenData) {
    _tokenData = tokenData;
    _reconnectAttempts = 0;
    _closeAll();
    if (tokenData?.accessToken != null && tokenData?.userId != null) _open(_url);
  }

  /// Drop the connection and open a new one. iOS can leave a suspended socket half-open without ever
  /// reporting it, so call this on resume.
  void reconnect() {
    if (_tokenData == null) return;
    connect(_tokenData);
  }

  void _open(String url, {bool migrating = false}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _migrating = migrating;
    final channel = IOWebSocketChannel.connect(Uri.parse(url));
    _channel = channel;
    _subscription = channel.stream.listen(
      (raw) => _receive(channel, raw),
      onDone: () => _lost(channel),
      onError: (_) => _lost(channel),
      cancelOnError: true,
    );
  }

  void _closeAll() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _closePrevious();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _closePrevious() {
    _previousSubscription?.cancel();
    _previousSubscription = null;
    _previousChannel?.sink.close();
    _previousChannel = null;
  }

  void _lost(IOWebSocketChannel channel) {
    if (channel == _previousChannel) {
      _closePrevious();
      return;
    }
    if (channel != _channel) return;
    _closeAll();
    if (_tokenData == null) return;
    final seconds = (1 << _reconnectAttempts).clamp(1, 60);
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () => _open(_url));
  }

  void _resetKeepalive() {
    _keepaliveTimer?.cancel();
    // A little slack on top of Twitch's interval before calling the connection dead.
    _keepaliveTimer = Timer(_keepalive + const Duration(seconds: 5), () {
      log('EventSub keepalive missed, reconnecting');
      final channel = _channel;
      if (channel != null) _lost(channel);
    });
  }

  Future<void> _receive(IOWebSocketChannel channel, dynamic raw) async {
    try {
      final message = json.decode(raw as String) as Map<String, dynamic>;
      final metadata = message['metadata'] as Map<String, dynamic>;
      final payload = message['payload'] as Map<String, dynamic>;
      if (channel == _channel) _resetKeepalive();

      switch (metadata['message_type']) {
        case 'session_welcome':
          if (channel != _channel) return;
          _reconnectAttempts = 0;
          final session = payload['session'] as Map<String, dynamic>;
          final keepalive = session['keepalive_timeout_seconds'];
          if (keepalive is int) _keepalive = Duration(seconds: keepalive);
          _resetKeepalive();
          if (_migrating) {
            // The subscriptions moved over with the session.
            _migrating = false;
            _closePrevious();
            return;
          }
          await _subscribe(session['id'] as String);
          break;
        case 'session_reconnect':
          if (channel != _channel) return;
          final url = (payload['session'] as Map<String, dynamic>)['reconnect_url'] as String;
          _closePrevious();
          _previousChannel = _channel;
          _previousSubscription = _subscription;
          _open(url, migrating: true);
          break;
        case 'notification':
          final id = metadata['message_id'] as String;
          if (_seenMessageIds.contains(id)) return;
          _seenMessageIds.add(id);
          if (_seenMessageIds.length > 100) _seenMessageIds.removeAt(0);
          if (metadata['subscription_type'] == 'user.whisper.message') _notifyWhisper(payload['event'] as Map<String, dynamic>);
          break;
        case 'revocation':
          log('EventSub subscription revoked: ${payload['subscription']?['status']}');
          break;
      }
    } catch (e) {
      log('Couldn\'t handle an EventSub message: $e');
    }
  }

  Future<void> _subscribe(String sessionId) async {
    final tokenData = _tokenData;
    if (tokenData == null) return;
    try {
      await Twitch.createEventSubSubscription(
        tokenData,
        type: 'user.whisper.message',
        version: '1',
        condition: {'user_id': tokenData.userId!},
        sessionId: sessionId,
      );
    } on TwitchRequestException catch (e) {
      log('Couldn\'t subscribe to whispers: $e');
      // Without a subscription Twitch closes the socket after 10 seconds, and retrying with the same token
      // fails the same way, so stay disconnected until the account changes.
      _tokenData = null;
      _closeAll();
      onSubscribeFailed?.call(e);
    } catch (e) {
      // Network trouble: drop the socket so the backoff retries.
      log('Couldn\'t subscribe to whispers: $e');
      final channel = _channel;
      if (channel != null) _lost(channel);
    }
  }

  void _notifyWhisper(Map<String, dynamic> event) {
    onWhisper(ReceivedWhisper(
      id: event['whisper_id'] as String,
      fromUserId: event['from_user_id'] as String,
      fromLogin: event['from_user_login'] as String,
      fromDisplayName: event['from_user_name'] as String,
      text: (event['whisper'] as Map<String, dynamic>)['text'] as String,
    ));
  }
}
