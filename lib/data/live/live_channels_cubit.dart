import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/twitch/helix_api.dart';
import '../../api/twitch/twitch_profile.dart';

/// Asks Helix which of [logins] are live, 100 per request (the most `GET /streams` takes), and returns those logins.
Future<Set<String>> liveLoginsFromHelix(HelixApi helix, List<String> logins) async {
  const perRequest = 100;
  final live = <String>{};
  for (var i = 0; i < logins.length; i += perRequest) {
    final streams = await helix.streams(userLogins: logins.skip(i).take(perRequest).toList());
    live.addAll([for (final stream in streams) stream.userLogin.toLowerCase()]);
  }
  return live;
}

/// Whether [login]'s channel is live, for the channel sheet: its [profile], which the sheet loads when it opens, is the
/// newest answer once it's there; until then the last round of [LiveChannelsCubit] (its [live] logins) says.
bool isChannelLive({required String login, required TwitchProfile? profile, required Set<String> live}) =>
    profile != null ? profile.stream != null : live.contains(login.replaceFirst('#', '').toLowerCase());

/// Which joined channels are live (their logins, lowercase, without `#`), for the live dot on the tabs.
///
/// Twitch has no push for this that fits: EventSub's `stream.online` over WebSocket only allows a handful of
/// subscriptions for channels that aren't the user's own, and IRC doesn't say. So, like other chat clients, this asks
/// Helix `GET /streams` for all joined channels at once: every [interval] while the app is in front, and right away
/// when a channel is joined, the account changes or the app comes back. Twitch caches that endpoint for a minute or
/// two anyway, so asking more often wouldn't be faster. In the background it doesn't ask at all.
///
/// Helix needs a login, so without one no channel is shown live.
class LiveChannelsCubit extends Cubit<Set<String>> {
  LiveChannelsCubit({
    required this._helix,
    required this._logins,
    required Stream<Object?> channelChanges,
    required this._accountChanges,
    this._liveLogins = liveLoginsFromHelix,
    this.interval = const Duration(seconds: 60),
    bool watchLifecycle = true,
  }) : super(const {}) {
    _channelSubscription = channelChanges.listen((_) => _onChannelsChanged());
    _accountChanges.addListener(_onAccountChanged);
    if (watchLifecycle) {
      _lifecycle = AppLifecycleListener(onResume: resumed, onPause: paused);
    }
    _startTimer();
    unawaited(refresh());
  }

  final HelixApi? Function() _helix;
  final Iterable<String> Function() _logins;
  final Listenable _accountChanges;
  final Future<Set<String>> Function(HelixApi helix, List<String> logins) _liveLogins;

  /// How often to ask while the app is in front.
  final Duration interval;

  late final StreamSubscription<Object?> _channelSubscription;
  AppLifecycleListener? _lifecycle;
  Timer? _timer;

  /// The logins the last answer was about; a channel joined since is asked about right away.
  Set<String> _checked = const {};

  /// Counts the requests; an answer that isn't the latest request's any more is dropped.
  int _generation = 0;

  Set<String> _currentLogins() => {for (final login in _logins()) login.replaceFirst('#', '').toLowerCase()};

  /// Asks now which channels are live.
  Future<void> refresh() async {
    final generation = ++_generation;
    final helix = _helix();
    final logins = _currentLogins();
    if (helix == null || logins.isEmpty) {
      _checked = logins;
      if (state.isNotEmpty) emit(const {});
      return;
    }
    try {
      final live = await _liveLogins(helix, logins.toList());
      if (isClosed || generation != _generation) return;
      _checked = logins;
      emit(live.intersection(logins));
    } catch (e) {
      // Keep showing the last answer; the next round asks again.
      log("Couldn't check which channels are live: $e");
    }
  }

  void _onChannelsChanged() {
    final logins = _currentLogins();
    if (logins.difference(_checked).isNotEmpty) {
      unawaited(refresh());
    } else if (state.difference(logins).isNotEmpty) {
      // Only channels left: drop them without asking.
      _checked = logins;
      emit(state.intersection(logins));
    }
  }

  void _onAccountChanged() => unawaited(refresh());

  /// The app came back to the front: ask now, then every [interval] again.
  void resumed() {
    _startTimer();
    unawaited(refresh());
  }

  /// The app went to the background: stop asking until it comes back.
  void paused() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _lifecycle?.dispose();
    _accountChanges.removeListener(_onAccountChanged);
    await _channelSubscription.cancel();
    return super.close();
  }
}
