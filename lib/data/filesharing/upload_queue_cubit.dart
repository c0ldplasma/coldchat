import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../api/filesharing/upload_host.dart';
import 'upload_task.dart';

/// Owns every in-flight upload.
///
/// Lives above the channel views so an upload survives tab switches and the
/// composer never has to await anything: it starts a task, keeps accepting
/// input, and gets the URL handed back through [completed] and
/// [takeUploadedUrls] when the host answers.
class UploadQueueCubit extends Cubit<List<UploadTask>> {
  UploadQueueCubit({
    Future<Uint8List> Function(String path)? readBytes,
    List<UploadHost>? hosts,
  }) : _readBytes = readBytes ?? _readFile,
       _hosts = hosts ?? UploadHosts.chain,
       super(const []);

  /// Seams for tests; the app uses the real file system and host chain.
  final Future<Uint8List> Function(String path) _readBytes;
  final List<UploadHost> _hosts;

  // Async read: readAsBytesSync on the UI isolate janks visibly on anything
  // large, and file pickers happily hand back 100MB videos.
  static Future<Uint8List> _readFile(String path) => File(path).readAsBytes();

  /// Signals finished uploads. A broadcast stream rather than a callback
  /// because every open channel tab listens and filters by
  /// [UploadTask.channelName] — a single callback would be overwritten by
  /// whichever tab registered last. The URLs themselves wait in
  /// [takeUploadedUrls]: a channel's view is disposed while its tab is off
  /// screen, and an event nobody hears would drop the URL.
  final StreamController<UploadTask> _completed = StreamController<UploadTask>.broadcast();

  Stream<UploadTask> get completed => _completed.stream;

  /// URLs of finished uploads per channel name that no composer has taken yet.
  final Map<String, List<String>> _uploadedUrls = {};

  /// Hands over (and forgets) the finished uploads' URLs for [channelName], oldest first.
  List<String> takeUploadedUrls(String channelName) => _uploadedUrls.remove(channelName) ?? const [];

  /// Keeps [task]'s URL for [takeUploadedUrls] and tells the listeners.
  @visibleForTesting
  void deliverCompleted(UploadTask task) {
    final url = task.url;
    if (url == null) return;
    _uploadedUrls.putIfAbsent(task.channelName, () => []).add(url);
    if (!_completed.isClosed) _completed.add(task);
  }

  static const Duration _stallTimeout = Duration(seconds: 45);

  /// How long to wait for the host once every byte is out. Separate from the
  /// stall timeout because nothing "moves" in this phase — the old code had no
  /// bound here except the 5-minute attempt cap.
  static const Duration _processingTimeout = Duration(seconds: 60);
  static const Duration _attemptTimeout = Duration(minutes: 5);

  int _nextId = 0;
  Timer? _stallWatchdog;

  /// Keeps finished-and-dismissed tasks out of the list while leaving failed
  /// ones visible until the user acts on them.
  void _publish() => emit(List.unmodifiable(state));

  List<UploadTask> tasksFor(String channelName) => state.where((task) => task.channelName == channelName).toList();

  Future<void> uploadFile({
    required String path,
    required String filename,
    required String channelName,
  }) async {
    final task = UploadTask(
      id: _nextId++,
      filename: filename,
      path: path,
      size: 0,
      channelName: channelName,
      hostName: _hosts.first.name,
    );
    emit([...state, task]);
    _ensureWatchdog();

    await _readAndRun(task);
  }

  /// Whether [task] should still go ahead: not cancelled, and still in the
  /// queue (a failed task can be dismissed while its retry reads the file).
  bool _isActive(UploadTask task) =>
      task.status != UploadStatus.cancelled && state.any((element) => element.id == task.id);

  Future<void> _readAndRun(UploadTask task) async {
    final Uint8List bytes;
    try {
      bytes = await _readBytes(task.path);
    } catch (e) {
      if (_isActive(task)) _failUnreadable(task, e);
      return;
    }
    // Reading a big video takes a while; the user may have cancelled meanwhile.
    if (!_isActive(task)) return;
    await _runChain(task, bytes);
  }

  /// Walk the host chain until one succeeds. Only a hard failure moves on —
  /// a cancellation stops everything.
  Future<void> _runChain(UploadTask task, Uint8List bytes) async {
    task.size = bytes.length;
    task.sent = 0;
    task.status = UploadStatus.uploading;
    task.attempts.clear();
    task.errorKind = null;
    task.errorHost = null;
    task.errorStatus = null;
    task.errorDetail = null;
    _publish();
    _ensureWatchdog();

    for (var i = 0; i < _hosts.length; i++) {
      final host = _hosts[i];
      if (!_isActive(task)) return;

      task.hostName = host.name;
      task.sent = 0;
      task.status = UploadStatus.uploading;
      task.lastProgressAt = DateTime.now();
      task.processingSince = null;
      task.abortFailure = null;
      final client = http.Client();
      task.client = client;
      _publish();

      try {
        final url = await host.upload(
          task.filename,
          bytes,
          client: client,
          timeout: _attemptTimeout,
          onProgress: (sent, total) {
            if (task.status == UploadStatus.cancelled) return;
            task.sent = sent;
            task.size = total;
            task.lastProgressAt = DateTime.now();
            if (sent >= total && task.status == UploadStatus.uploading) {
              task.status = UploadStatus.processing;
              task.processingSince = DateTime.now();
            }
            _publish();
          },
        );

        if (task.status == UploadStatus.cancelled) return;
        task.status = UploadStatus.done;
        task.url = url;
        task.client = null;
        _publish();
        deliverCompleted(task);
        remove(task);
        return;
      } catch (e) {
        if (task.status == UploadStatus.cancelled) return;
        // Prefer the watchdog's reason: closing the client to abort shows up
        // here as an opaque "connection closed" error.
        final failure =
            task.abortFailure ?? (e is UploadFailure ? e : UploadFailure(host.name, UploadFailureKind.unknown, '$e'));
        // Recorded for every host, so the chip can say "Retrying with nuuls…"
        // while the chain continues, and the details dialog can list them all.
        task.attempts.add(failure);
        if (i == _hosts.length - 1) _failChain(task);
      } finally {
        client.close();
        if (identical(task.client, client)) task.client = null;
      }
    }
  }

  /// Turn the per-host failures into the one thing worth telling the user.
  ///
  /// Offline is decided here, at the end, rather than on the first network
  /// error: a failed lookup for one host can just mean that host's domain is
  /// dead, and bailing early would skip the fallback in exactly the case it
  /// exists for. When the phone really is offline the remaining hosts fail in
  /// well under a second, so walking them costs nothing.
  void _failChain(UploadTask task) {
    final attempts = task.attempts;
    final last = attempts.last;

    // A mid-upload drop shows up as a stall on the host that was carrying it,
    // then instant network errors on the rest — so allow timeouts in the mix,
    // but require the final word to be a network error.
    final offline =
        last.kind == UploadFailureKind.network &&
        attempts.every((f) => f.kind == UploadFailureKind.network || f.kind == UploadFailureKind.timeout);

    task.errorKind = offline
        ? UploadErrorKind.offline
        : switch (last.kind) {
            UploadFailureKind.network => UploadErrorKind.network,
            UploadFailureKind.timeout => UploadErrorKind.timeout,
            UploadFailureKind.http => UploadErrorKind.rejected,
            UploadFailureKind.badResponse => UploadErrorKind.badResponse,
            UploadFailureKind.unknown => UploadErrorKind.unknown,
          };
    task.errorHost = last.hostName;
    task.errorStatus = last.statusCode;
    _markFailed(task);
  }

  void _failUnreadable(UploadTask task, Object error) {
    task.errorKind = UploadErrorKind.unreadableFile;
    task.errorDetail = '$error';
    _markFailed(task);
  }

  void _markFailed(UploadTask task) {
    task.status = UploadStatus.failed;
    task.client = null;
    _publish();
  }

  Future<void> retry(UploadTask task) async {
    // Leave the failed state before the first await, so a second tap while the
    // file is read is a no-op instead of starting a second chain on this task.
    if (task.status != UploadStatus.failed || !_isActive(task)) return;
    task.status = UploadStatus.uploading;
    task.sent = 0;
    task.lastProgressAt = DateTime.now();
    task.errorKind = null;
    _publish();
    _ensureWatchdog();
    await _readAndRun(task);
  }

  void cancel(UploadTask task) {
    task.status = UploadStatus.cancelled;
    task.client?.close();
    task.client = null;
    remove(task);
  }

  void remove(UploadTask task) {
    emit(List.unmodifiable(state.where((element) => element.id != task.id)));
    if (state.isEmpty) {
      _stallWatchdog?.cancel();
      _stallWatchdog = null;
    }
  }

  /// A socket that goes quiet produces no error and no timeout — the request
  /// just hangs. Abort it ourselves so the chain can move to the next host, or
  /// the chip can offer a retry, instead of spinning forever.
  ///
  /// Ticks every second rather than every few because it also drives the
  /// elapsed-seconds label while waiting on a host.
  void _ensureWatchdog() {
    _stallWatchdog ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      var waitingOnHost = false;
      for (final task in state) {
        switch (task.status) {
          case UploadStatus.uploading:
            if (now.difference(task.lastProgressAt) > _stallTimeout) {
              _abort(
                task,
                UploadFailure(task.hostName, UploadFailureKind.timeout, 'stalled for ${_stallTimeout.inSeconds}s'),
              );
            }
          case UploadStatus.processing:
            waitingOnHost = true;
            final since = task.processingSince;
            if (since != null && now.difference(since) > _processingTimeout) {
              _abort(
                task,
                UploadFailure(
                  task.hostName,
                  UploadFailureKind.timeout,
                  'no response ${_processingTimeout.inSeconds}s after upload',
                ),
              );
            }
          case UploadStatus.done:
          case UploadStatus.failed:
          case UploadStatus.cancelled:
            break;
        }
      }
      if (waitingOnHost) _publish();
    });
  }

  /// Record why, then close the client; the pending await in [_runChain] throws
  /// and treats it like any other failure — falling through to the next host
  /// unless this was the last one.
  void _abort(UploadTask task, UploadFailure reason) {
    if (task.abortFailure != null) return; // already aborting this attempt
    task.abortFailure = reason;
    task.client?.close();
  }

  @override
  Future<void> close() {
    _stallWatchdog?.cancel();
    for (final task in state) {
      task.client?.close();
    }
    unawaited(_completed.close());
    return super.close();
  }
}
