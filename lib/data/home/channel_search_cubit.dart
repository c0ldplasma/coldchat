import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/twitch/helix_api.dart';
import '../../tools/channel_ranking.dart';
import '../twitch/channel_search.dart';

/// The channel search on the home tab.
@immutable
sealed class ChannelSearchState {
  const ChannelSearchState();
}

/// No search: the home tab shows the streams.
class ChannelSearchIdle extends ChannelSearchState {
  const ChannelSearchIdle();
}

class ChannelSearchLoading extends ChannelSearchState {
  const ChannelSearchLoading();
}

class ChannelSearchLoaded extends ChannelSearchState {
  final List<ChannelCandidate> results;

  const ChannelSearchLoaded(this.results);
}

class ChannelSearchFailed extends ChannelSearchState {
  const ChannelSearchFailed();
}

/// Searches channels as the user types, once typing pauses for [debounce], so a fast typist doesn't send a search
/// per letter. Only the answer to the latest query is shown.
class ChannelSearchCubit extends Cubit<ChannelSearchState> {
  ChannelSearchCubit({
    required this._helix,
    this.debounce = const Duration(milliseconds: 250),
    this._search = searchChannels,
  }) : super(const ChannelSearchIdle());

  /// Helix as the active account, or null without one (then nothing is searched).
  final HelixApi? Function() _helix;
  final Future<List<ChannelCandidate>> Function(HelixApi helix, String query) _search;
  final Duration debounce;

  Timer? _debounceTimer;

  /// Counts the searches; an answer whose number isn't the latest any more is dropped.
  int _generation = 0;

  /// The search field changed to [text].
  void queryChanged(String text) {
    _debounceTimer?.cancel();
    if (normalizeChannelQuery(text).isEmpty) {
      clear();
      return;
    }
    _debounceTimer = Timer(debounce, () => unawaited(_run(text)));
  }

  /// Ends the search (emptied field, or a result was opened): back to the streams.
  void clear() {
    _debounceTimer?.cancel();
    if (isClosed) return;
    _generation++;
    emit(const ChannelSearchIdle());
  }

  Future<void> _run(String text) async {
    final helix = _helix();
    if (helix == null || isClosed) return;
    final generation = ++_generation;
    emit(const ChannelSearchLoading());
    ChannelSearchState result;
    try {
      result = ChannelSearchLoaded(await _search(helix, text));
    } catch (_) {
      result = const ChannelSearchFailed();
    }
    if (isClosed || generation != _generation) return;
    emit(result);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
