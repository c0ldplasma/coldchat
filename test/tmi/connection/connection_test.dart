import 'dart:async';

import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:coldchat/tmi/connection/connection_state.dart' as tmi;
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeSink implements WebSocketSink {
  bool closed = false;
  final List<String> sent = [];

  @override
  void add(dynamic data) => sent.add(data as String);

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

  /// Twitch sending [data], one or more lines separated by CRLF.
  void receive(String data) => _controller.add(data);

  /// Twitch closing the socket, which makes [Connection] schedule a reconnect.
  Future<void> closeFromServer() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [Connection] that records the parsed lines it gets, before its filter decides whether to handle them.
class _RecordingConnection extends Connection {
  _RecordingConnection({super.openSocket});

  final List<String> parsed = [];

  @override
  Future<void> receive(irc.Message event) {
    parsed.add(event.command);
    return super.receive(event);
  }
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
    // The first retry comes after the 1s backoff.
    await Future<void>.delayed(const Duration(milliseconds: 1300));

    expect(sockets, hasLength(2));
    expect(connection.channel, same(sockets.last));
  });

  test('each failed connect counts once toward the backoff: retries after 1s, then 2s', () async {
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

    // onError and onDone both fire for one failed socket; only one of them may schedule the retry.
    sockets.last.failToConnect(Exception('no network'));
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(sockets, hasLength(2));

    sockets.last.failToConnect(Exception('no network'));
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(sockets, hasLength(2));
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    expect(sockets, hasLength(3));
    expect(connection.channel, same(sockets.last));
  });

  group('acceptedCommands', () {
    Future<(_RecordingConnection, _FakeSocket)> connected({Set<String>? acceptedCommands}) async {
      final sockets = <_FakeSocket>[];
      final connection = _RecordingConnection(
        openSocket: (_) {
          final socket = _FakeSocket();
          sockets.add(socket);
          return socket;
        },
      )..acceptedCommands = acceptedCommands;
      addTearDown(connection.close);
      connection.add(ConnectionConnect(_account()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return (connection, sockets.single);
    }

    const accepted = {'001', 'GLOBALUSERSTATE', 'USERSTATE', 'JOIN', 'NOTICE'};

    test('drops the other lines before parsing them, handles the accepted ones and always answers PING', () async {
      final (connection, socket) = await connected(acceptedCommands: accepted);
      final handled = <String>[];
      connection.onReceive = (_, message) => handled.add(message.command);

      socket.receive(
        [
          '@id=1;user-id=2 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hi',
          '@msg-id=sub :tmi.twitch.tv USERNOTICE #ronni :sub',
          '@room-id=1 :tmi.twitch.tv CLEARCHAT #ronni :someone',
          '@room-id=1 :tmi.twitch.tv ROOMSTATE #ronni',
          ':tmi.twitch.tv 001 justinfan123 :Welcome, GLHF!',
          '@color=#FF0000 :tmi.twitch.tv GLOBALUSERSTATE',
          '@badges=moderator/1 :tmi.twitch.tv USERSTATE #ronni',
          ':justinfan123!justinfan123@justinfan123.tmi.twitch.tv JOIN #ronni',
          '@msg-id=slow_on :tmi.twitch.tv NOTICE #ronni :This room is now in slow mode.',
          'PING :tmi.twitch.tv',
        ].join('\r\n'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const expected = ['001', 'GLOBALUSERSTATE', 'USERSTATE', 'JOIN', 'NOTICE', 'PING'];
      expect(connection.parsed, expected);
      expect(handled, expected);
      expect(socket.sink.sent.last, 'PONG :tmi.twitch.tv');
    });

    test('without it, every line is parsed and handled', () async {
      final (connection, socket) = await connected();
      final handled = <String>[];
      connection.onReceive = (_, message) => handled.add(message.command);

      socket.receive(
        '@id=1 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hi\r\n'
        '@room-id=1 :tmi.twitch.tv ROOMSTATE #ronni',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(connection.parsed, ['PRIVMSG', 'ROOMSTATE']);
      expect(handled, ['PRIVMSG', 'ROOMSTATE']);
    });
  });
}
