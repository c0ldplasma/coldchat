import 'dart:async';
import 'dart:typed_data';

import 'package:coldchat/api/filesharing/upload_host.dart';
import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/filesharing/upload_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// A host whose answers the test hands out one by one.
class FakeHost extends UploadHost {
  final List<Completer<String>> calls = [];

  @override
  String get name => 'Fake';

  @override
  Duration? get retention => null;

  @override
  Uri get endpoint => Uri.parse('https://example.invalid');

  @override
  String get fileField => 'file';

  @override
  Future<String> upload(
    String filename,
    Uint8List bytes, {
    required UploadProgress onProgress,
    required http.Client client,
    Duration timeout = const Duration(seconds: 120),
  }) {
    final call = Completer<String>();
    calls.add(call);
    return call.future;
  }
}

void main() {
  late FakeHost host;
  late List<Completer<Uint8List>> reads;
  late UploadQueueCubit queue;
  late List<UploadTask> completed;
  late StreamSubscription<UploadTask> subscription;

  setUp(() {
    host = FakeHost();
    reads = [];
    queue = UploadQueueCubit(
      hosts: [host],
      readBytes: (path) {
        final read = Completer<Uint8List>();
        reads.add(read);
        return read.future;
      },
    );
    completed = [];
    subscription = queue.completed.listen(completed.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await queue.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<UploadTask> failedTask() async {
    unawaited(queue.uploadFile(path: '/a.png', filename: 'a.png', channelName: 'chan'));
    final task = queue.state.single;
    reads.removeLast().complete(Uint8List(3));
    await settle();
    host.calls.removeLast().completeError(UploadFailure('Fake', UploadFailureKind.http, 'HTTP 500', statusCode: 500));
    await settle();
    expect(task.status, UploadStatus.failed);
    return task;
  }

  test('cancelling while the file is read stops the upload', () async {
    final upload = queue.uploadFile(path: '/a.mp4', filename: 'a.mp4', channelName: 'chan');
    final task = queue.state.single;

    queue.cancel(task);
    reads.single.complete(Uint8List(3));
    await upload;

    expect(task.status, UploadStatus.cancelled);
    expect(host.calls, isEmpty);
    expect(queue.state, isEmpty);
    expect(completed, isEmpty);
  });

  test('a failed read after cancelling leaves the task cancelled', () async {
    final upload = queue.uploadFile(path: '/a.mp4', filename: 'a.mp4', channelName: 'chan');
    final task = queue.state.single;

    queue.cancel(task);
    reads.single.completeError(Exception('gone'));
    await upload;

    expect(task.status, UploadStatus.cancelled);
    expect(queue.state, isEmpty);
  });

  test('a second retry tap while the file is read is ignored', () async {
    final task = await failedTask();

    final first = queue.retry(task);
    expect(task.status, UploadStatus.uploading);
    final second = queue.retry(task);
    expect(reads, hasLength(1));

    await second;
    reads.single.complete(Uint8List(3));
    await settle();
    expect(host.calls, hasLength(1));

    host.calls.single.complete('https://example.invalid/a.png');
    await first;
    await settle();
    expect(completed, [task]);
    expect(task.status, UploadStatus.done);
    expect(queue.state, isEmpty);
  });

  test('cancelling a retry while the file is read stops it', () async {
    final task = await failedTask();

    final retry = queue.retry(task);
    queue.cancel(task);
    reads.single.complete(Uint8List(3));
    await retry;

    expect(task.status, UploadStatus.cancelled);
    expect(host.calls, isEmpty);
    expect(completed, isEmpty);
  });
}
