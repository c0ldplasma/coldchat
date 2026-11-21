import 'package:coldchat/api/twitch/helix_api.dart';
import 'package:coldchat/api/twitch/twitch_auth_api.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/client/account_session.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:coldchat/tmi/connection/connection_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../api/fake_api.dart';

/// A transmitter that records the events it's sent, in whatever [state] the test sets.
class _FakeConnection implements Connection {
  @override
  ConnectionState state = ConnectionDisconnected();

  @override
  bool credentialsRejected = false;

  final List<ConnectionEvent> events = [];

  @override
  TwitchAccount? get twitchAccount => switch (state) {
    final ConnectionStateWithCredentials state => state.twitchAccount,
    _ => null,
  };

  @override
  void add(ConnectionEvent event) => events.add(event);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TwitchAccount _account(String login, {DateTime? expiresAt, String? accessToken = 'token'}) => TwitchAccount(
  tokenData: TokenData(
    clientId: 'coldchat',
    login: login,
    scopes: const [],
    userId: '$login-id',
    expiresAt: expiresAt,
    accessToken: accessToken == null ? null : '$accessToken-$login',
  ),
  userData: null,
  cookies: null,
);

final _validToken = http.Response(
  '{"client_id":"coldchat","login":"x","scopes":["chat:read"],"user_id":"1","expires_in":3600}',
  200,
);

void main() {
  late _FakeConnection transmitter;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request request) answer;
  late List<TwitchAccount?> accountChanges;
  late int leftChannels;
  late int apiAccessGained;
  late List<String> blockChanges;

  setUp(() {
    transmitter = _FakeConnection();
    requests = [];
    answer = (request) async => request.url.path == '/oauth2/validate' ? _validToken : http.Response('', 204);
    accountChanges = [];
    leftChannels = 0;
    apiAccessGained = 0;
    blockChanges = [];
  });

  AccountSession session({TwitchAccount? account}) {
    final api = fakeApi((request) => answer(request), requests: requests);
    late final AccountSession session;
    session = AccountSession(
      transmitter: transmitter,
      helix: HelixApi(api, () => session.apiTokenData),
      twitchAuth: TwitchAuthApi(api),
      account: account,
      onApiAccessGained: () => apiAccessGained++,
      onAccountChanged: accountChanges.add,
      onTransmitterLeftChannels: () => leftChannels++,
      onBlockedChanged: blockChanges.add,
    );
    addTearDown(session.close);
    return session;
  }

  Iterable<String> validations() =>
      requests.where((request) => request.url.path == '/oauth2/validate').map((r) => r.headers['Authorization']!);

  group('connectAs', () {
    test('logs the transmitter in, switches the account and validates the token', () async {
      final s = session();
      final moddy = _account('moddy');
      s.ownColor = '#FF0000';

      await s.connectAs(moddy);
      await pumpEventQueue();

      expect(transmitter.events, [ConnectionConnect(moddy)]);
      expect(s.apiTokenData, same(moddy.tokenData));
      expect(s.ownColor, isNull);
      expect(accountChanges, [moddy]);
      expect(leftChannels, 1);
      expect(apiAccessGained, 1);
      expect(validations(), ['Bearer token-moddy']);
      expect(moddy.tokenData.scopes, ['chat:read']);
    });

    test('loads what needs a token only when there was none before', () async {
      final s = session(account: _account('moddy'));

      await s.connectAs(_account('other'));

      expect(apiAccessGained, 0);
    });

    test('rejects a token that has expired without connecting', () async {
      final s = session();
      final expired = _account('moddy', expiresAt: DateTime(2020));

      await s.connectAs(expired);

      expect(transmitter.events, [ConnectionCredentialsRejected(expired)]);
      expect(accountChanges, isEmpty);
      expect(leftChannels, 1);
      expect(requests, isEmpty);
    });
  });

  test('disconnect logs the transmitter out and forgets the account', () async {
    final s = session(account: _account('moddy'));
    s.ownColor = '#FF0000';

    s.disconnect();

    expect(transmitter.events, [ConnectionDisconnect()]);
    expect(s.apiTokenData, isNull);
    expect(s.ownColor, isNull);
    expect(accountChanges, [null]);
    expect(leftChannels, 1);
  });

  group('validateCredentials', () {
    test('rejects the login when Twitch answers 401', () async {
      final moddy = _account('moddy');
      final s = session(account: moddy);
      answer = (request) async => http.Response('{"status":401,"message":"invalid access token"}', 401);

      await s.validateCredentials(moddy);

      expect(transmitter.events, [ConnectionCredentialsRejected(moddy)]);
    });

    test('does not reject the login on a network error', () async {
      final moddy = _account('moddy');
      final s = session(account: moddy);
      answer = (request) async => throw http.ClientException('offline', request.url);

      await s.validateCredentials(moddy);

      expect(transmitter.events, isEmpty);
    });

    test('ignores a rejection of an account that is not active anymore', () async {
      final previous = _account('previous');
      final s = session(account: _account('moddy'));
      answer = (request) async => http.Response('{"status":401,"message":"invalid access token"}', 401);

      await s.validateCredentials(previous);

      expect(transmitter.events, isEmpty);
    });

    test('sends nothing for an anonymous account', () async {
      final anonymous = _account('justinfan1', accessToken: null);
      final s = session(account: anonymous);

      await s.validateCredentials(anonymous);

      expect(requests, isEmpty);
      expect(s.apiTokenData, isNull);
    });
  });

  group('an auth-failure NOTICE', () {
    final failure = irc.Message.fromEvent(':tmi.twitch.tv NOTICE * :Login authentication failed');

    test('on the transmitter rejects its login', () {
      final moddy = _account('moddy');
      final s = session(account: moddy);
      transmitter.state = ConnectionConnecting(moddy);

      expect(s.handleAuthFailureNotice(transmitter, failure), isTrue);
      expect(transmitter.events, [ConnectionCredentialsRejected(moddy)]);
    });

    test('on another connection is swallowed without rejecting anything', () {
      final s = session(account: _account('moddy'));
      final receiver = _FakeConnection()..state = ConnectionConnecting(_account('justinfan1', accessToken: null));

      expect(s.handleAuthFailureNotice(receiver, failure), isTrue);
      expect(transmitter.events, isEmpty);
    });

    test('is told apart from channel notices', () {
      expect(AccountSession.isAuthFailureNotice(failure), isTrue);
      expect(
        AccountSession.isAuthFailureNotice(irc.Message.fromEvent(':tmi.twitch.tv NOTICE * :Improperly formatted auth')),
        isTrue,
      );
      expect(
        AccountSession.isAuthFailureNotice(
          irc.Message.fromEvent(':tmi.twitch.tv NOTICE #ronni :Login authentication failed'),
        ),
        isFalse,
      );
      expect(AccountSession.isAuthFailureNotice(irc.Message.fromEvent(':tmi.twitch.tv NOTICE * :Welcome')), isFalse);
    });
  });

  group('on resume', () {
    test('validates a live login and asks for the transmitter to be probed', () async {
      final moddy = _account('moddy');
      final s = session(account: moddy);
      transmitter.state = ConnectionConnected(moddy);

      expect(s.checkLoginOnResume(), isTrue);
      await pumpEventQueue();
      expect(validations(), ['Bearer token-moddy']);
    });

    test('rejects an expired login without probing', () {
      final expired = _account('moddy', expiresAt: DateTime(2020));
      final s = session(account: expired);
      transmitter.state = ConnectionConnected(expired);

      expect(s.checkLoginOnResume(), isFalse);
      expect(transmitter.events, [ConnectionCredentialsRejected(expired)]);
    });

    test('leaves a refused or missing login alone', () {
      final moddy = _account('moddy');
      final s = session(account: moddy);
      expect(s.checkLoginOnResume(), isFalse);

      transmitter
        ..state = ConnectionInvalidCredentials(moddy)
        ..credentialsRejected = true;
      expect(s.checkLoginOnResume(), isFalse);
      expect(requests, isEmpty);
    });
  });

  group('blocking', () {
    test('blocks and unblocks a user on Twitch and rebuilds their messages', () async {
      final moddy = _account('moddy');
      final s = session(account: moddy);
      transmitter.state = ConnectionConnected(moddy);
      expect(s.blockingUserId, 'moddy-id');
      expect(s.ownLogin, 'moddy');

      await s.setBlocked('42', true);
      expect(s.isBlocked('42'), isTrue);
      expect(requests.last.method, 'PUT');
      expect(requests.last.url.queryParameters['target_user_id'], '42');

      await s.setBlocked('42', false);
      expect(s.isBlocked('42'), isFalse);
      expect(requests.last.method, 'DELETE');
      expect(blockChanges, ['42', '42']);
    });

    test('needs a connected login', () async {
      final s = session(account: _account('moddy'));

      expect(s.blockingUserId, isNull);
      expect(s.isBlocked('42'), isFalse);
      expect(s.ownLogin, isNull);
      await expectLater(s.setBlocked('42', true), throwsException);
      expect(requests, isEmpty);
    });

    test('fills in the block list of a logged-in connection only', () async {
      answer = (request) async => http.Response('{"data":[{"user_id":"7"}],"pagination":{}}', 200);
      final s = session();
      final connected = ConnectionConnected(_account('moddy'));
      final anonymous = ConnectionConnected(_account('justinfan1', accessToken: null));

      s.loadBlockedUsers(connected);
      s.loadBlockedUsers(anonymous);
      await pumpEventQueue();

      expect(connected.blockedUserIds, ['7']);
      expect(anonymous.blockedUserIds, isEmpty);
      expect(requests, hasLength(1));
    });
  });
}
