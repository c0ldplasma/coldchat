import 'dart:convert';

import 'package:coldchat/api/recentmessages/recentmessages.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/client/chat_history.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../api/fake_api.dart';
import 'fake_client.dart';

/// Chat message number [i] in `#forsen`, with the id `id-[i]`.
String _line(int i) => '@id=id-$i;tmi-sent-ts=${1000 + i} :a!a@a.tmi.twitch.tv PRIVMSG #forsen :message $i';

void main() {
  late Channel channel;
  late Connection receiver;
  late List<String> received;

  setUp(() {
    channel = Channel(client: FakeClient(), name: '#forsen');
    addTearDown(channel.close);
    receiver = Connection(name: 'receiver');
    addTearDown(receiver.close);
    received = [];
  });

  ChatHistory history({required Future<http.Response> Function(http.Request) answer, bool enabled = true}) =>
      ChatHistory(
        recentMessages: RecentMessages(enabled: () => enabled, api: fakeApi(answer)),
        receiver: receiver,
        channels: () => [channel],
        receive: (connection, message) async {
          expect(connection, same(receiver));
          received.add(message.parameters.last);
        },
      );

  /// What recent-messages answers for [lines].
  Future<http.Response> Function(http.Request) answering(List<String> lines) =>
      (request) async => http.Response(jsonEncode({'messages': lines}), 200);

  group('insertHistoryMessages', () {
    test('hands the newest ${ChatHistory.firstChunk} lines over first, then older ones in chunks', () async {
      final h = history(answer: answering(const []));
      final lines = [for (var i = 0; i < 100; i++) _line(i)];

      final inserting = h.insertHistoryMessages(receiver, lines);
      // The first chunk is handed over before the first pause.
      expect(received, [for (var i = 70; i < 100; i++) 'message $i']);
      await inserting;

      expect(received, [
        for (var i = 70; i < 100; i++) 'message $i',
        for (var i = 30; i < 70; i++) 'message $i',
        for (var i = 0; i < 30; i++) 'message $i',
      ]);
    });

    test('leaves out room state, notices, USERSTATE, broken lines and lines it has handed over already', () async {
      final h = history(answer: answering(const []));

      await h.insertHistoryMessages(receiver, [
        _line(1),
        '@room-id=1 :tmi.twitch.tv ROOMSTATE #forsen',
        '@msg-id=slow_on :tmi.twitch.tv NOTICE #forsen :This room is now in slow mode.',
        '@badges=moderator/1 :tmi.twitch.tv USERSTATE #forsen',
        '',
        _line(1),
        _line(2),
      ]);

      expect(received, ['message 1', 'message 2']);
      expect(ChatHistory.skippedInHistory(irc.Message.fromEvent('@x=1 :tmi.twitch.tv USERNOTICE #forsen :sub')), false);
    });
  });

  group('ensureRecentMessages', () {
    test('fetches the history once and puts the channel first in the JOIN queue', () async {
      final requests = <http.Request>[];
      final h = ChatHistory(
        recentMessages: RecentMessages(
          enabled: () => true,
          api: fakeApi(answering([_line(1)]), requests: requests),
        ),
        receiver: receiver,
        channels: () => [channel],
        receive: (connection, message) async => received.add(message.parameters.last),
      );

      await h.ensureRecentMessages(channel);
      await h.ensureRecentMessages(channel);

      expect(requests.single.url, RecentMessages.uri('forsen'));
      expect(received, ['message 1']);
      expect(channel.joinPriority, isTrue);
      expect(channel.recentMessagesEverFetched, isTrue);
    });

    test('sends nothing while chat history is off, and asks again next time', () async {
      final requests = <http.Request>[];
      var enabled = false;
      final h = ChatHistory(
        recentMessages: RecentMessages(
          enabled: () => enabled,
          api: fakeApi(answering([_line(1)]), requests: requests),
        ),
        receiver: receiver,
        channels: () => [channel],
        receive: (connection, message) async => received.add(message.parameters.last),
      );

      await h.ensureRecentMessages(channel);
      expect(requests, isEmpty);
      expect(channel.recentMessagesFetched, isFalse);

      enabled = true;
      await h.ensureRecentMessages(channel);
      expect(requests, hasLength(1));
      expect(received, ['message 1']);
    });

    test('a failed fetch is tried again the next time', () async {
      var fail = true;
      final h = history(
        answer: (request) async => fail
            ? http.Response('Bad Gateway', 502)
            : http.Response(
                jsonEncode({
                  'messages': [_line(1)],
                }),
                200,
              ),
      );

      await h.ensureRecentMessages(channel);
      expect(received, isEmpty);
      expect(channel.recentMessagesFetched, isFalse);

      fail = false;
      await h.ensureRecentMessages(channel);
      expect(received, ['message 1']);
      expect(channel.recentMessagesFetched, isTrue);
    });
  });

  test('joining fetches the history again only for a channel that was opened, once', () async {
    final requests = <http.Request>[];
    final h = ChatHistory(
      recentMessages: RecentMessages(
        enabled: () => true,
        api: fakeApi(answering([_line(1)]), requests: requests),
      ),
      receiver: receiver,
      channels: () => [channel],
      receive: (connection, message) async => received.add(message.parameters.last),
    );

    h.joined(channel);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(requests, isEmpty);

    channel.recentMessagesEverFetched = true;
    h.joined(channel);
    h.joined(channel);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(requests, hasLength(1));
    expect(channel.joinBackfillDone, isTrue);
  });

  test('refetch fetches every given channel again and allows the next JOIN backfill', () async {
    final h = history(answer: answering([_line(1)]));
    channel.joinBackfillDone = true;

    await h.refetch([channel]);

    expect(received, ['message 1']);
    expect(channel.joinBackfillDone, isFalse);
  });
}
