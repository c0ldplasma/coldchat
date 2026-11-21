import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/filesharing/upload_task.dart';
import 'package:coldchat/tmi/channel/composer_draft.dart';
import 'package:flutter_test/flutter_test.dart';

UploadTask _finished(String channelName, String url) => UploadTask(
  id: 0,
  filename: 'a.png',
  path: '/tmp/a.png',
  size: 1,
  channelName: channelName,
  hostName: 'host',
)..url = url;

void main() {
  group('ComposerDraft', () {
    test('starts empty with the caret at the end', () {
      final draft = ComposerDraft();
      expect(draft.text, '');
      expect(draft.reply, isNull);
      expect(draft.restoredCaret, 0);
    });

    test('keeps what was saved', () {
      final draft = ComposerDraft()..save(text: 'hello world', caret: 5, reply: null);
      expect(draft.text, 'hello world');
      expect(draft.restoredCaret, 5);
    });

    test('an invalid caret restores to the end', () {
      expect((ComposerDraft()..save(text: 'abc', caret: -1, reply: null)).restoredCaret, 3);
      expect((ComposerDraft()..save(text: 'abc', caret: 10, reply: null)).restoredCaret, 3);
    });
  });

  group('UploadQueueCubit.takeUploadedUrls', () {
    test('keeps finished URLs until the channel takes them', () async {
      final queue = UploadQueueCubit();
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
      final queue = UploadQueueCubit();
      addTearDown(queue.close);

      final next = queue.completed.first;
      queue.deliverCompleted(_finished('foo', 'https://a'));
      expect((await next).channelName, 'foo');
      expect(queue.takeUploadedUrls('foo'), ['https://a']);
    });
  });
}
