import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:coldchat/api/recentmessages/recentmessages.dart';
import 'package:coldchat/data/repositories/channel_repository.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/channel_state.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_ban.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_notice.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_state.dart' as tmi;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../api/fake_api.dart';

class _FakeSink implements WebSocketSink {
  final List<String> sent = [];
  bool closed = false;

  @override
  void add(dynamic data) => sent.add(data as String);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSocket implements WebSocketChannel {
  final StreamController<dynamic> _controller = StreamController<dynamic>();

  @override
  Future<void> get ready => Future.value();

  @override
  // ignore: close_sinks, the connection under test closes it.
  final _FakeSink sink = _FakeSink();

  @override
  Stream<dynamic> get stream => _controller.stream;

  /// Twitch sending [line] on this socket.
  void receive(String line) => _controller.add(line);

  /// The nick this socket registered with.
  String get nick => sink.sent.lastWhere((line) => line.startsWith('NICK ')).substring(5);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One side of Twitch's IRC server: the sockets a [Connection] opened, newest last.
class _Server {
  final List<_FakeSocket> sockets = [];

  late final Connection connection;

  _Server(String name) {
    connection = Connection(
      name: name,
      membership: name != 'transmitter',
      openSocket: (_) {
        final socket = _FakeSocket();
        sockets.add(socket);
        return socket;
      },
    );
  }

  _FakeSocket get socket => sockets.last;

  List<String> get sent => socket.sink.sent;

  /// Twitch accepting the login of the current socket.
  Future<void> welcome() async {
    socket.receive(':tmi.twitch.tv 001 ${socket.nick} :Welcome, GLHF!');
    await _settle();
  }

  /// Twitch echoing the current socket's JOIN of [channel].
  Future<void> echoJoin(String channel, {String? nick}) async {
    final login = nick ?? socket.nick;
    socket.receive(':$login!$login@$login.tmi.twitch.tv JOIN $channel');
    await _settle();
  }

  Future<void> receive(String line) async {
    socket.receive(line);
    await _settle();
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 10));

TwitchAccount _account(String login, {String? userId}) => TwitchAccount(
  tokenData: TokenData(
    clientId: 'coldchat',
    login: login,
    scopes: const [],
    userId: userId ?? '${login.hashCode}',
    expiresAt: null,
    accessToken: 'token-$login',
  ),
  userData: null,
  cookies: null,
);

/// A USERSTATE for [channel] with [badges].
String _userState(String channel, String badges) =>
    '@badge-info=;badges=$badges;color=#1E90FF;display-name=Moddy;emote-sets=0;mod=0;subscriber=0;user-type= '
    ':tmi.twitch.tv USERSTATE $channel';

class _Setup {
  final Client client;
  final _Server receiver;
  final _Server transmitter;

  _Setup(this.client, this.receiver, this.transmitter);

  Channel channel(String name) => client.channels.state.firstWhere((channel) => channel.name == name);
}

void main() {
  late Directory tempDir;
  late Future<http.Response> Function(http.Request request) twitchAnswer;

  /// What Twitch's API answers: [validateStatus] for token validation, nothing for everything else.
  void answerTwitchApi({int validateStatus = 200}) {
    twitchAnswer = (request) async {
      if (request.url.path == '/oauth2/validate') {
        return validateStatus == 200
            ? http.Response(
                '{"client_id":"coldchat","login":"x","scopes":[],"user_id":"1","expires_in":0}',
                200,
              )
            : http.Response('{"status":401,"message":"invalid access token"}', validateStatus);
      }
      return http.Response('{"data":[]}', 200);
    };
  }

  setUpAll(Hive.registerAdapters);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_client_connections_test');
    Hive.init(tempDir.path);
    answerTwitchApi();
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  /// A client with the channels [channels], logged in as [account] (or not), whose connections are both welcomed by
  /// Twitch and have joined every channel.
  Future<_Setup> start({TwitchAccount? account, List<String> channels = const ['#ronni', '#forsen']}) async {
    await (await Hive.openBox<dynamic>(ChannelRepository.boxName)).addAll(channels);
    final receiver = _Server('receiver');
    final transmitter = _Server('transmitter');
    // Answered by whatever twitchAnswer is at the time of the request, so a test can change it midway.
    final api = fakeApi((request) => twitchAnswer(request));
    final client = Client(
      api: api,
      twitchAccount: account,
      channelRepository: await ChannelRepository.open(),
      recentMessages: RecentMessages(enabled: () => false, api: api),
      receiver: receiver.connection,
      transmitter: transmitter.connection,
      providers: const [],
    );
    addTearDown(client.close);
    await _settle();
    return _Setup(client, receiver, transmitter);
  }

  /// [start], with both connections welcomed and every channel joined on both.
  Future<_Setup> joined({TwitchAccount? account, List<String> channels = const ['#ronni', '#forsen']}) async {
    final setup = await start(account: account, channels: channels);
    await setup.receiver.welcome();
    expect(setup.receiver.sent, contains('JOIN ${channels.join(',')}'));
    for (final channel in channels) {
      await setup.receiver.echoJoin(channel);
    }
    if (account != null) {
      await setup.transmitter.welcome();
      expect(setup.transmitter.sent, contains('JOIN ${channels.join(',')}'));
      for (final channel in channels) {
        await setup.transmitter.echoJoin(channel);
      }
    }
    return setup;
  }

  group('the receiver', () {
    test('connects anonymously without an account, and nothing else connects', () async {
      final setup = await start();

      expect(setup.receiver.sockets, hasLength(1));
      expect(setup.receiver.socket.nick, matches(RegExp(r'^justinfan\d+$')));
      expect(setup.receiver.sent.where((line) => line.startsWith('PASS')), isEmpty);
      expect(setup.transmitter.sockets, isEmpty);
      expect(setup.transmitter.connection.state, isA<tmi.ConnectionDisconnected>());
    });

    test('connects anonymously with an account too; only the transmitter logs in', () async {
      final setup = await start(account: _account('moddy'));

      expect(setup.receiver.socket.nick, startsWith('justinfan'));
      expect(setup.receiver.sent.where((line) => line.startsWith('PASS')), isEmpty);
      expect(setup.transmitter.socket.nick, 'moddy');
      expect(setup.transmitter.sent, contains('PASS oauth:token-moddy'));
    });

    test('joins the channels and takes the echo for its justinfan nick as the acknowledgment', () async {
      final setup = await start();
      await setup.receiver.welcome();

      expect(setup.receiver.sent, contains('JOIN #ronni,#forsen'));
      expect(setup.channel('#ronni').state, isA<ChannelConnecting>());

      // Someone else joining is not the acknowledgment.
      await setup.receiver.echoJoin('#ronni', nick: 'someone');
      expect(setup.channel('#ronni').state, isA<ChannelConnecting>());

      await setup.receiver.echoJoin('#ronni');
      expect(setup.channel('#ronni').state, isA<ChannelConnected>());
      expect(setup.channel('#forsen').state, isA<ChannelConnecting>());
    });

    test('shows chat, and ignores USERSTATE: the anonymous user is not the account', () async {
      final setup = await joined(account: _account('moddy'));
      final ronni = setup.channel('#ronni');
      await setup.transmitter.receive(_userState('#ronni', 'moderator/1'));

      await setup.receiver.receive(
        '@id=m1;user-id=1337;tmi-sent-ts=1 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hello',
      );
      await setup.receiver.receive(_userState('#ronni', ''));

      expect(ronni.channelMessages.state.whereType<ChannelMessageChat>(), hasLength(1));
      expect(ronni.ownUserIsModerator, isTrue);
    });
  });

  group('the transmitter', () {
    test('ignores chat traffic, so nothing is shown twice', () async {
      final setup = await joined(account: _account('moddy'));
      final ronni = setup.channel('#ronni');

      for (final line in [
        '@id=m1;user-id=1337 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hello',
        '@id=n1;msg-id=sub;user-id=1337 :tmi.twitch.tv USERNOTICE #ronni :sub',
        '@room-id=12826;target-user-id=1337 :tmi.twitch.tv CLEARCHAT #ronni :ronni',
        '@login=ronni;target-msg-id=m1 :tmi.twitch.tv CLEARMSG #ronni :hello',
        '@emote-only=0;room-id=12826;slow=0 :tmi.twitch.tv ROOMSTATE #ronni',
        ':someone!someone@someone.tmi.twitch.tv JOIN #ronni',
        ':someone!someone@someone.tmi.twitch.tv PART #ronni',
      ]) {
        await setup.transmitter.receive(line);
      }

      expect(ronni.channelMessages.state.whereType<ChannelMessageChat>(), isEmpty);
      expect(ronni.channelMessages.state.whereType<ChannelMessageBan>(), isEmpty);
      expect(ronni.id, isNull);
    });

    test('handles only its own handshake, USERSTATE, JOIN echoes and NOTICEs', () {
      expect(Client.transmitterCommands, {'001', 'GLOBALUSERSTATE', 'USERSTATE', 'JOIN', 'NOTICE'});
    });

    test('drops chat lines before they are handled, still answers PING, and asks for no membership', () async {
      final setup = await joined(account: _account('moddy'));
      final connection = setup.transmitter.connection;
      final handled = <String>[];
      final onReceive = connection.onReceive!;
      connection.onReceive = (connection, message) {
        handled.add(message.command);
        onReceive(connection, message);
      };

      for (var i = 0; i < 20; i++) {
        await setup.transmitter.receive('@id=x$i;user-id=1 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hi $i');
      }
      expect(handled, isEmpty);

      await setup.transmitter.receive('PING :tmi.twitch.tv');
      expect(setup.transmitter.sent.last, 'PONG :tmi.twitch.tv');

      expect(setup.transmitter.sent.first, 'CAP REQ :twitch.tv/tags twitch.tv/commands');
      expect(setup.receiver.sent.first, 'CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership');
    });

    test('joins the channels within the rate limit, with its own scheduler', () async {
      final channels = [for (var i = 0; i < 30; i++) '#channel$i'];
      final setup = await start(account: _account('moddy'), channels: channels);
      await setup.receiver.welcome();
      await setup.transmitter.welcome();

      List<String> joinedChannels(_Server server) => [
        for (final line in server.sent.where((line) => line.startsWith('JOIN '))) ...line.substring(5).split(','),
      ];
      // The receiver's JOINs don't use up the transmitter's limit, and the other way round.
      expect(joinedChannels(setup.receiver), hasLength(12));
      expect(joinedChannels(setup.transmitter), hasLength(12));
    });
  });

  group('sending', () {
    test('is possible only once the transmitter is connected and its JOIN was acknowledged', () async {
      final setup = await start(account: _account('moddy'));
      await setup.receiver.welcome();
      await setup.receiver.echoJoin('#ronni');
      final ronni = setup.channel('#ronni');

      // Reading works, but the transmitter isn't in yet.
      expect(ronni.state, isA<ChannelConnected>());
      expect(ronni.canSend, isFalse);

      await setup.transmitter.welcome();
      expect(setup.transmitter.sent, contains('JOIN #ronni,#forsen'));
      expect(ronni.canSend, isFalse);

      await setup.transmitter.echoJoin('#ronni');
      expect(ronni.canSend, isTrue);
      expect(setup.channel('#forsen').canSend, isFalse);

      await ronni.send('hi');
      expect(setup.transmitter.sent.last, 'PRIVMSG #ronni :hi');
      expect(setup.receiver.sent.where((line) => line.startsWith('PRIVMSG')), isEmpty);
    });

    test('is not possible without an account, while reading works', () async {
      final setup = await joined();

      expect(setup.channel('#ronni').state, isA<ChannelConnected>());
      expect(setup.channel('#ronni').canSend, isFalse);
    });
  });

  group('switching accounts', () {
    test('reconnects only the transmitter and keeps the chat live', () async {
      final setup = await joined(account: _account('moddy'));
      final ronni = setup.channel('#ronni');
      final receiverLines = setup.receiver.sent.length;
      final states = <ChannelState>[];
      final subscription = ronni.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await setup.client.connectAs(_account('other'));
      await _settle();

      // The receiver: same socket, nothing sent, the channel neither parted nor rejoined.
      expect(setup.receiver.sockets, hasLength(1));
      expect(setup.receiver.socket.sink.closed, isFalse);
      expect(setup.receiver.sent, hasLength(receiverLines));
      expect(states, isEmpty);
      expect(ronni.state, isA<ChannelConnected>());

      // The transmitter: a new socket as the new account, and nothing can be sent until it has joined.
      expect(setup.transmitter.sockets, hasLength(2));
      expect(setup.transmitter.sockets.first.sink.closed, isTrue);
      expect(setup.transmitter.socket.nick, 'other');
      expect(ronni.canSend, isFalse);

      await setup.transmitter.welcome();
      await setup.transmitter.echoJoin('#ronni');
      expect(ronni.canSend, isTrue);
      expect(setup.receiver.sockets, hasLength(1));
    });

    test('forgets the moderator status of the previous account and takes the new one from USERSTATE', () async {
      final setup = await joined(account: _account('moddy'));
      final ronni = setup.channel('#ronni');
      await setup.transmitter.receive(_userState('#ronni', 'moderator/1'));
      expect(ronni.ownUserIsModerator, isTrue);

      await setup.client.connectAs(_account('viewer'));
      await _settle();
      expect(ronni.ownUserIsModerator, isFalse);

      await setup.transmitter.welcome();
      await setup.transmitter.echoJoin('#ronni');
      await setup.transmitter.receive(_userState('#ronni', 'subscriber/1'));
      expect(ronni.ownUserIsModerator, isFalse);

      await setup.client.connectAs(_account('moddy'));
      await _settle();
      await setup.transmitter.welcome();
      await setup.transmitter.receive(_userState('#ronni', 'moderator/1'));
      expect(ronni.ownUserIsModerator, isTrue);
    });

    test('mentions follow the account that is logged in', () async {
      final setup = await joined(account: _account('moddy'));
      expect(setup.client.session.ownLogin, 'moddy');

      await setup.client.connectAs(_account('other'));
      expect(setup.client.session.ownLogin, 'other');

      setup.client.disconnect();
      await _settle();
      expect(setup.client.session.ownLogin, isNull);
    });
  });

  group('logging out', () {
    test('disconnects the transmitter and keeps the receiver reading', () async {
      final setup = await joined(account: _account('moddy'));
      final ronni = setup.channel('#ronni');

      setup.client.disconnect();
      await _settle();

      expect(setup.transmitter.connection.state, isA<tmi.ConnectionDisconnected>());
      expect(setup.transmitter.socket.sink.closed, isTrue);
      expect(setup.receiver.connection.state, isA<tmi.ConnectionConnected>());
      expect(setup.receiver.socket.sink.closed, isFalse);
      expect(ronni.state, isA<ChannelConnected>());
      expect(ronni.canSend, isFalse);

      await setup.receiver.receive('@id=m2;user-id=1337 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :still here');
      expect(ronni.channelMessages.state.whereType<ChannelMessageChat>(), hasLength(1));
    });
  });

  group('a rejected login', () {
    test('locks only the transmitter when Twitch refuses the handshake', () async {
      final setup = await start(account: _account('moddy'));
      await setup.receiver.welcome();

      await setup.transmitter.receive(':tmi.twitch.tv NOTICE * :Login authentication failed');

      expect(setup.transmitter.connection.state, isA<tmi.ConnectionInvalidCredentials>());
      expect(setup.receiver.connection.state, isA<tmi.ConnectionConnected>());
      expect(setup.receiver.connection.credentialsRejected, isFalse);
    });

    test('locks only the transmitter when the token turns out to be invalid', () async {
      final setup = await joined(account: _account('moddy'));
      answerTwitchApi(validateStatus: 401);
      await setup.client.session.validateCredentials(setup.client.transmitter.twitchAccount!);
      await _settle();

      expect(setup.transmitter.connection.state, isA<tmi.ConnectionInvalidCredentials>());
      expect(setup.receiver.connection.state, isA<tmi.ConnectionConnected>());
      expect(setup.channel('#ronni').state, isA<ChannelConnected>());
    });

    test('of an account that is no longer active does not lock out the active one', () async {
      final previous = _account('moddy');
      final setup = await joined(account: previous);
      await setup.client.connectAs(_account('other'));
      await _settle();
      await setup.transmitter.welcome();

      answerTwitchApi(validateStatus: 401);
      await setup.client.session.validateCredentials(previous);
      await _settle();

      expect(setup.transmitter.connection.state, isA<tmi.ConnectionConnected>());
    });

    test('an anonymous receiver ignores an auth failure NOTICE', () async {
      final setup = await start();
      await setup.receiver.welcome();

      await setup.receiver.receive(':tmi.twitch.tv NOTICE * :Login authentication failed');

      expect(setup.receiver.connection.state, isA<tmi.ConnectionConnected>());
    });
  });

  group('NOTICEs', () {
    const slowOn = '@msg-id=slow_on :tmi.twitch.tv NOTICE #ronni :This room is now in slow mode.';

    test('about the channel are shown once when both connections get them', () async {
      final setup = await joined(account: _account('moddy'));
      final ronni = setup.channel('#ronni');

      await setup.receiver.receive(slowOn);
      await setup.transmitter.receive(slowOn);

      expect(ronni.channelMessages.state.whereType<ChannelMessageNotice>(), hasLength(1));
    });

    test('answering a sent message are shown, they only reach the transmitter', () async {
      final setup = await joined(account: _account('moddy'));
      final ronni = setup.channel('#ronni');

      await setup.transmitter.receive(
        '@msg-id=msg_ratelimit :tmi.twitch.tv NOTICE #ronni :Your message was not sent because you are sending '
        'messages too quickly.',
      );

      expect(ronni.channelMessages.state.whereType<ChannelMessageNotice>(), hasLength(1));
    });

    test('of a suspended channel change its state only from the receiver', () async {
      final setup = await joined(account: _account('moddy'));
      const suspended =
          '@msg-id=msg_channel_suspended :tmi.twitch.tv NOTICE #ronni :This channel does not exist or has been '
          'suspended.';

      await setup.transmitter.receive(suspended);
      expect(setup.channel('#ronni').state, isA<ChannelConnected>());
      expect(setup.channel('#ronni').channelMessages.state.whereType<ChannelMessageNotice>(), isEmpty);

      await setup.receiver.receive(suspended);
      expect(setup.channel('#ronni').state, isA<ChannelSuspended>());
    });

    test('isDuplicateNotice compares msg-id and text within a few seconds', () {
      final now = DateTime(2026, 11, 21, 12);
      final notice = irc.Message.fromEvent(slowOn);
      final shown = [ChannelMessageNotice(message: notice, dateTime: now)];

      expect(Client.isDuplicateNotice(shown, notice, now.add(const Duration(seconds: 2))), isTrue);
      expect(Client.isDuplicateNotice(shown, notice, now.add(const Duration(seconds: 30))), isFalse);
      expect(
        Client.isDuplicateNotice(
          shown,
          irc.Message.fromEvent('@msg-id=slow_off :tmi.twitch.tv NOTICE #ronni :This room is no longer in slow mode.'),
          now,
        ),
        isFalse,
      );
      expect(Client.isDuplicateNotice(const [], notice, now), isFalse);
    });
  });

  test('isOwnJoin matches the registered nick, ignoring case', () {
    final join = irc.Message.fromEvent(':justinfan123!justinfan123@justinfan123.tmi.twitch.tv JOIN #ronni');

    expect(Client.isOwnJoin(join, 'justinfan123'), isTrue);
    expect(Client.isOwnJoin(join, 'JustinFan123'), isTrue);
    expect(Client.isOwnJoin(join, 'moddy'), isFalse);
  });

  test('anonymousAccount is a justinfan login without a token', () {
    final account = Client.anonymousAccount(Random(1));

    expect(account.tokenData.login, matches(RegExp(r'^justinfan\d{5}$')));
    expect(account.tokenData.accessToken, isNull);
    expect(Connection.describe(tmi.ConnectionConnected(account)), 'anonymous');
    expect(Connection.describe(tmi.ConnectionConnected(_account('moddy'))), 'moddy');
  });
}
