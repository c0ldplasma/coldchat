import 'dart:collection';
import 'dart:math' show min;

/// Keeps the JOINs the client sends within Twitch's rate limit and notices JOINs that never got an answer.
///
/// Twitch allows 20 JOINs per 10 seconds per user for normal accounts
/// (https://dev.twitch.tv/docs/chat/#rate-limits); every channel in a comma-separated JOIN counts. Going over gets
/// JOINs dropped silently, so the limit is enforced over a rolling window, with a safety margin by default.
///
/// A channel whose JOIN gets no echo (dropped by Twitch) would otherwise wait forever. After [timeout] it is reported
/// by [takeTimedOut] and becomes due for another JOIN: right away for the first [maxAttempts] JOINs, then after a delay
/// that starts at [firstBackoff] and doubles up to [maxBackoff], so a channel that keeps going unanswered is still
/// retried on a healthy connection without hammering it. An echo or [reset] (a reconnect) starts it over. Channels that
/// can't be joined at all (suspended or nonexistent) are answered with a NOTICE instead; the client stops retrying them.
///
/// The clock is injectable so the class can be tested without waiting.
class JoinScheduler {
  final int limit;
  final Duration window;
  final Duration timeout;
  final int maxAttempts;
  final Duration firstBackoff;
  final Duration maxBackoff;
  final DateTime Function() _now;

  /// When each JOIN in the current window was sent, oldest first.
  final Queue<DateTime> _sent = Queue();

  /// Channels whose JOIN is still unanswered, with the time it was sent.
  final Map<String, DateTime> _pending = {};

  /// JOINs sent per channel since the last [reset] or echo.
  final Map<String, int> _attempts = {};

  /// Channels whose JOIN timed out, with the time they may be sent another one.
  final Map<String, DateTime> _retryAt = {};

  JoinScheduler({
    this.limit = 18,
    this.window = const Duration(seconds: 10),
    this.timeout = const Duration(seconds: 20),
    this.maxAttempts = 3,
    this.firstBackoff = const Duration(seconds: 30),
    this.maxBackoff = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// How many JOINs can be sent right now without going over [limit] in the last [window].
  int get available {
    final cutoff = _now().subtract(window);
    while (_sent.isNotEmpty && !_sent.first.isAfter(cutoff)) {
      _sent.removeFirst();
    }
    return limit - _sent.length;
  }

  /// Records a JOIN sent for each of [channels].
  void sent(Iterable<String> channels) {
    final now = _now();
    for (final channel in channels) {
      _sent.addLast(now);
      _pending[channel] = now;
      _attempts[channel] = (_attempts[channel] ?? 0) + 1;
      _retryAt.remove(channel);
    }
  }

  /// Twitch echoed the JOIN for [channel].
  void acknowledged(String channel) {
    _pending.remove(channel);
    _attempts.remove(channel);
    _retryAt.remove(channel);
  }

  /// Whether a JOIN for [channel] was sent and is still waiting for its echo.
  bool isPending(String channel) => _pending.containsKey(channel);

  /// Whether [channel]'s JOIN timed out and the delay before the next one has passed.
  bool isDue(String channel) => _retryAt[channel]?.isAfter(_now()) == false;

  /// Whether [channel] may be sent a JOIN now: it isn't waiting for an echo or for the delay after a timeout.
  bool canJoin(String channel) => !isPending(channel) && _retryAt[channel]?.isAfter(_now()) != true;

  /// How long [channel] waits before its next JOIN after a timeout: nothing for the first [maxAttempts] JOINs, then
  /// [firstBackoff], doubling with every further JOIN up to [maxBackoff].
  Duration retryDelay(String channel) {
    final extra = (_attempts[channel] ?? 0) - maxAttempts;
    if (extra < 0) return Duration.zero;
    final delay = firstBackoff * (1 << min(extra, 20));
    return delay < maxBackoff ? delay : maxBackoff;
  }

  /// The channels whose JOIN has been unanswered for longer than [timeout]. They stop being pending and become due
  /// for another JOIN after [retryDelay].
  List<String> takeTimedOut() {
    final now = _now();
    final cutoff = now.subtract(timeout);
    final timedOut = [
      for (final entry in _pending.entries)
        if (!entry.value.isAfter(cutoff)) entry.key,
    ];
    for (final channel in timedOut) {
      _pending.remove(channel);
      _retryAt[channel] = now.add(retryDelay(channel));
    }
    return timedOut;
  }

  /// Forgets pending JOINs and retry counts, e.g. after a reconnect. The rate window is kept: the limit is per user,
  /// not per connection.
  void reset() {
    _pending.clear();
    _attempts.clear();
    _retryAt.clear();
  }
}
