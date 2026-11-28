import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/filesharing/upload_task.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/channel/composer_draft.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:flutter_test/flutter_test.dart';

import '../api/fake_api.dart';

UploadTask _finished(String channelName, String url) => UploadTask(
  id: 0,
  filename: 'a.png',
  path: '/tmp/a.png',
  size: 1,
  channelName: channelName,
  hostName: 'host',
)..url = url;

ChannelMessageChat _message() => ChannelMessageChat(
  message: irc.Message.fromEvent('@id=message-1 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hello'),
  dateTime: DateTime(2026, 11, 21),
);

void main() {
  group('ComposerDraft', () {
    test('starts empty with the caret at the end', () {
      final draft = ComposerDraft();
      expect(draft.text, '');
      expect(draft.state, isNull);
      expect(draft.restoredCaret, 0);
    });

    test('keeps what was saved', () {
      final draft = ComposerDraft()..save(text: 'hello world', caret: 5);
      expect(draft.text, 'hello world');
      expect(draft.restoredCaret, 5);
    });

    test('an invalid caret restores to the end', () {
      expect((ComposerDraft()..save(text: 'abc', caret: -1)).restoredCaret, 3);
      expect((ComposerDraft()..save(text: 'abc', caret: 10)).restoredCaret, 3);
    });

    test('holds the reply target as state and tells listeners when it changes', () async {
      final draft = ComposerDraft();
      addTearDown(draft.close);
      final states = <ChannelMessageChat?>[];
      final subscription = draft.stream.listen(states.add);
      addTearDown(subscription.cancel);
      final message = _message();

      draft.replyTo(message);
      expect(draft.state, same(message));
      draft.replyTo(null);
      await Future<void>.delayed(Duration.zero);

      expect(draft.state, isNull);
      expect(states, [same(message), isNull]);
    });

    test('a reply after the channel closed is ignored', () async {
      final draft = ComposerDraft();
      await draft.close();
      draft.replyTo(_message());
      expect(draft.state, isNull);
    });

    test('a mention goes to the shown view, not to the saved text', () async {
      final draft = ComposerDraft()..save(text: 'hi', caret: 1);
      addTearDown(draft.close);
      final mentions = <String>[];
      final subscription = draft.mentions.listen(mentions.add);

      draft.mention('ronni');
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(mentions, ['@ronni']);
      expect(draft.text, 'hi');
      expect(draft.restoredCaret, 1);
    });

    test('without a view a mention is appended to the saved text, caret at the end', () async {
      final draft = ComposerDraft()..save(text: 'hi  there ', caret: 1);
      addTearDown(draft.close);

      draft.mention('ronni');

      expect(draft.text, 'hi there @ronni');
      expect(draft.restoredCaret, draft.text.length);
    });

    test('an emote from the panel goes to the shown view, not to the saved text', () async {
      final draft = ComposerDraft()..save(text: 'hi', caret: 1);
      addTearDown(draft.close);
      final insertions = <String>[];
      final subscription = draft.insertions.listen(insertions.add);

      draft.insert('Kappa');
      await subscription.cancel();

      expect(insertions, ['Kappa']);
      expect(draft.text, 'hi');
    });

    test('without a view an emote is appended to the saved text', () async {
      final draft = ComposerDraft()..save(text: 'hi', caret: 1);
      addTearDown(draft.close);

      draft.insert('Kappa');

      expect(draft.text, 'hi Kappa');
      expect(draft.restoredCaret, draft.text.length);
    });
  });

  group('UploadQueueCubit.takeUploadedUrls', () {
    test('keeps finished URLs until the channel takes them', () async {
      final queue = UploadQueueCubit(api: offlineApi());
      addTearDown(queue.close);

      // Nobody listens, as when the channel's tab is off screen.
      queue.deliverCompleted(_finished('foo', 'https://a'));
      queue.deliverCompleted(_finished('bar', 'https://b'));
      queue.deliverCompleted(_finished('foo', 'https://c'));

      expect(queue.takeUploadedUrls('foo'), ['https://a', 'https://c']);
      expect(queue.takeUploadedUrls('foo'), isEmpty);
      expect(queue.takeUploadedUrls('bar'), ['https://b']);
    });

    test('tells listeners about finished uploads', () async {
      final queue = UploadQueueCubit(api: offlineApi());
      addTearDown(queue.close);

      final next = queue.completed.first;
      queue.deliverCompleted(_finished('foo', 'https://a'));
      expect((await next).channelName, 'foo');
      expect(queue.takeUploadedUrls('foo'), ['https://a']);
    });
  });
}
