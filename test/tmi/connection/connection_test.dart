import 'dart:async';

import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeSink implements WebSocketSink {
  bool closed = false;

  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSocket implements WebSocketChannel {
  _FakeSocket({Duration cancelDelay = Duration.zero})
    : _controller = StreamController<dynamic>(onCancel: () => Future<void>.delayed(cancelDelay));

  final StreamController<dynamic> _controller;
  final Completer<void> _ready = Completer<void>();

  @override
  Future<void> get ready => _ready.future;

  /// Fails like a real socket whose host lookup failed: `ready` completes with
  /// the error, and the stream reports it and closes.
  void failToConnect(Object error) {
    _ready.completeError(error);
    _controller.addError(error);
    unawaited(_controller.close());
  }

  @override
  // ignore: close_sinks, closing it is what Connection is tested for.
  final _FakeSink sink = _FakeSink();

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TwitchAccount _account() => TwitchAccount(
  tokenData: TokenData(
    clientId: null,
    login: 'justinfan123',
    scopes: const [],
    userId: null,
    expiresAt: null,
    accessToken: null,
  ),
  userData: null,
  cookies: null,
);

void main() {
  test('two reconnects at once leave exactly one socket open', () async {
    final sockets = <_FakeSocket>[];
    final connection = Connection(
      openSocket: (_) {
        // The first socket is slow to cancel, so the first reconnect is still
        // tearing it down when the second one runs.
        final socket = _FakeSocket(cancelDelay: Duration(milliseconds: sockets.isEmpty ? 50 : 0));
        sockets.add(socket);
        return socket;
      },
    );
    addTearDown(connection.close);

    connection.add(ConnectionConnect(_account()));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(sockets, hasLength(1));

    connection.add(ConnectionReconnect());
    connection.add(ConnectionReconnect());
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(sockets, hasLength(2));
    expect(connection.channel, same(sockets.last));
    expect(sockets.first.sink.closed, isTrue);
    expect(sockets.last.sink.closed, isFalse);
  });

  test('a failed connect is handled and reconnects', () async {
    final sockets = <_FakeSocket>[];
    final connection = Connection(
      openSocket: (_) {
        final socket = _FakeSocket();
        sockets.add(socket);
        return socket;
      },
    );
    addTearDown(connection.close);

    connection.add(ConnectionConnect(_account()));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(sockets, hasLength(1));

    // An unhandled `ready` error would fail this test as an uncaught async error.
    sockets.first.failToConnect(Exception("Failed host lookup: 'irc-ws.chat.twitch.tv'"));
    // onError and onDone both schedule the reconnect; the second one sets the 2s backoff.
    await Future<void>.delayed(const Duration(milliseconds: 2300));

    expect(sockets, hasLength(2));
    expect(connection.channel, same(sockets.last));
  });
}
