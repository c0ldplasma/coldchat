import 'package:flutter_bloc/flutter_bloc.dart';

import 'emote_cache.dart';

class EmoteCacheState {
  /// The cache's size on disk, `null` until it was read (or when reading failed).
  final int? bytes;
  final bool clearing;

  const EmoteCacheState({this.bytes, this.clearing = false});
}

/// The emote cache's size and the "clear" action for Settings.
class EmoteCacheCubit extends Cubit<EmoteCacheState> {
  final Future<int> Function() _readSize;
  final Future<void> Function() _clear;

  EmoteCacheCubit({required this._readSize, required this._clear}) : super(const EmoteCacheState());

  factory EmoteCacheCubit.of(EmoteCacheManager manager) =>
      EmoteCacheCubit(readSize: manager.totalBytes, clear: manager.emptyCache);

  Future<void> load() async {
    final bytes = await _tryReadSize();
    if (!isClosed) emit(EmoteCacheState(bytes: bytes, clearing: state.clearing));
  }

  Future<void> clear() async {
    if (state.clearing) return;
    emit(EmoteCacheState(bytes: state.bytes, clearing: true));
    try {
      await _clear();
    } catch (_) {
      // Whatever was removed shows in the size read below.
    }
    final bytes = await _tryReadSize();
    if (!isClosed) emit(EmoteCacheState(bytes: bytes));
  }

  /// The size, or `null` when it can't be read: then Settings leaves it out instead of showing a wrong one.
  Future<int?> _tryReadSize() async {
    try {
      return await _readSize();
    } catch (_) {
      return null;
    }
  }
}
