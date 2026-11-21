import 'dart:async';

import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:coldchat/tmi/connection/connection_state.dart' as tmi;
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

  @override
  // ignore: close_sinks, closing it is what Connection is tested for.
  final _FakeSink sink = _FakeSink();

  @override
  Stream<dynamic> get stream => _controller.stream;

  /// Twitch closing the socket, which makes [Connection] schedule a reconnect.
  Future<void> closeFromServer() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TwitchAccount _account([String login = 'justinfan123']) => TwitchAccount(
  tokenData: TokenData(
    clientId: null,
    login: login,
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

  group('ConnectionDisconnect (logging out)', () {
    /// A connection whose sockets are fakes collected in [sockets], connected as `ronni`.
    Future<Connection> connected(List<_FakeSocket> sockets) async {
      final connection = Connection(
        openSocket: (_) {
          final socket = _FakeSocket();
          sockets.add(socket);
          return socket;
        },
      );
      addTearDown(connection.close);
      connection.add(ConnectionConnect(_account('ronni')));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(sockets, hasLength(1));
      return connection;
    }

    test('closes the socket and ends up disconnected', () async {
      final sockets = <_FakeSocket>[];
      final connection = await connected(sockets);

      connection.add(ConnectionDisconnect());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sockets.single.sink.closed, isTrue);
      expect(connection.channel, isNull);
      expect(connection.state, isA<tmi.ConnectionDisconnected>());
      expect(connection.twitchAccount, isNull);
    });

    test('keeps the bloc usable: a later login opens a new socket as the new account', () async {
      final sockets = <_FakeSocket>[];
      final connection = await connected(sockets);
      connection.add(ConnectionDisconnect());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      connection.add(ConnectionConnect(_account('moddy')));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(connection.isClosed, isFalse);
      expect(sockets, hasLength(2));
      expect(connection.channel, same(sockets.last));
      expect(sockets.last.sink.closed, isFalse);
      expect(connection.twitchAccount?.tokenData.login, 'moddy');
    });

    test('a reconnect afterwards (app resume, watchdog) does not bring the old account back', () async {
      final sockets = <_FakeSocket>[];
      final connection = await connected(sockets);
      connection.add(ConnectionDisconnect());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      connection.forceReconnect();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(sockets, hasLength(1));
      expect(connection.state, isA<tmi.ConnectionDisconnected>());
    });

    test('a pending backoff reconnect from before the logout does not bring the old account back', () async {
      final sockets = <_FakeSocket>[];
      final connection = await connected(sockets);
      // Twitch drops the socket, so a reconnect is scheduled in a second; the user logs out before it fires.
      await sockets.single.closeFromServer();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      connection.add(ConnectionDisconnect());

      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(sockets, hasLength(1));
      expect(connection.state, isA<tmi.ConnectionDisconnected>());
    });
  });
}
