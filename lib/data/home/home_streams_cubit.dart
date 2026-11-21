import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/twitch/helix_api.dart';
import '../twitch/stream_data.dart';

/// One of the home tab's stream lists: still loading, loaded, or failed.
@immutable
class StreamList {
  /// The streams, once loaded.
  final List<StreamData>? streams;

  final bool failed;

  const StreamList.loading() : streams = null, failed = false;

  const StreamList.loaded(List<StreamData> this.streams) : failed = false;

  const StreamList.failed() : streams = null, failed = true;

  bool get isLoading => streams == null && !failed;
}

/// The home tab's stream lists, for the active account.
@immutable
class HomeStreamsState {
  /// Whether an account is active. Without one nothing is loaded.
  final bool loggedIn;

  /// The streams of [HomeStreamsCubit.recommendedLogins] that are live.
  final StreamList recommended;

  /// Twitch's most watched streams.
  final StreamList top;

  const HomeStreamsState({
    required this.loggedIn,
    this.recommended = const StreamList.loading(),
    this.top = const StreamList.loading(),
  });

  const HomeStreamsState.loggedOut() : this(loggedIn: false);

  HomeStreamsState copyWith({StreamList? recommended, StreamList? top}) =>
      HomeStreamsState(loggedIn: loggedIn, recommended: recommended ?? this.recommended, top: top ?? this.top);
}

/// Loads the recommended and top streams for the home tab.
///
/// Lives above the home page's tab view, which disposes the home tab on every tab switch, so the lists survive
/// switching to a chat and back. Reloads when the active account changes, on [refresh], and in the background when
/// the home tab is shown with lists older than [maxAge] ([homeShown]).
class HomeStreamsCubit extends Cubit<HomeStreamsState> {
  HomeStreamsCubit({
    required this._helix,
    required this._accountChanges,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const HomeStreamsState.loggedOut()) {
    _accountChanges.addListener(_onAccountChanged);
    _onAccountChanged();
  }

  /// Helix as the active account, or null without one.
  final HelixApi? Function() _helix;
  final Listenable _accountChanges;
  final DateTime Function() _now;

  /// How old the lists may get before showing the home tab reloads them.
  static const Duration maxAge = Duration(minutes: 5);

  static const List<String> recommendedLogins = [
    'forsen',
    'btmc',
    'nymn',
    'vaxei_osu',
    'mrekkosu',
    'shigetora',
    'kitboga',
    'cdawgva',
    'gigguk',
    'vedal987',
  ];

  /// Counts the loads; a load whose number isn't the latest any more is dropped when it finishes.
  int _generation = 0;

  /// When the lists shown were loaded, or null while there are none.
  DateTime? _loadedAt;

  /// The load in flight, if any.
  Future<void>? _loading;

  // A different account (or none): its lists are not this one's, so start over with spinners.
  void _onAccountChanged() {
    _loadedAt = null;
    final helix = _helix();
    if (helix == null) {
      _generation++;
      _loading = null;
      emit(const HomeStreamsState.loggedOut());
      return;
    }
    emit(const HomeStreamsState(loggedIn: true));
    unawaited(_load(helix));
  }

  /// Loads the lists again, keeping the ones shown until the new ones are there. Completes when both lists are
  /// done, for a pull-to-refresh.
  Future<void> refresh() {
    final helix = _helix();
    if (helix == null || isClosed) return Future.value();
    return _load(helix);
  }

  /// The home tab was built (again): reloads in the background if the lists are older than [maxAge].
  void homeShown() {
    if (!state.loggedIn || _loading != null) return;
    final loadedAt = _loadedAt;
    if (loadedAt != null && _now().difference(loadedAt) < maxAge) return;
    unawaited(refresh());
  }

  Future<void> _load(HelixApi helix) {
    final generation = ++_generation;
    bool current() => !isClosed && generation == _generation;

    Future<void> loadList(
      Future<List<StreamData>> request,
      StreamList Function(HomeStreamsState state) shown,
      HomeStreamsState Function(StreamList list) update,
    ) async {
      StreamList list;
      try {
        list = StreamList.loaded(await request);
      } catch (_) {
        list = const StreamList.failed();
      }
      if (!current()) return;
      // A failed reload keeps the list already shown.
      if (list.failed && shown(state).streams != null) return;
      emit(update(list));
    }

    final loading =
        Future.wait([
          loadList(
            helix.streams(userLogins: recommendedLogins),
            (state) => state.recommended,
            (list) => state.copyWith(recommended: list),
          ),
          loadList(helix.streams(), (state) => state.top, (list) => state.copyWith(top: list)),
        ]).then((_) {
          if (!current()) return;
          _loading = null;
          // After a failure, showing the home tab again tries again right away.
          if (!state.recommended.failed && !state.top.failed) _loadedAt = _now();
        });
    _loading = loading;
    return loading;
  }

  @override
  Future<void> close() {
    _accountChanges.removeListener(_onAccountChanged);
    return super.close();
  }
}
