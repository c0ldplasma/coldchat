import 'dart:collection';

/// Keeps the JOINs the client sends within Twitch's rate limit and notices JOINs that never got an answer.
///
/// Twitch allows 20 JOINs per 10 seconds per user for normal accounts
/// (https://dev.twitch.tv/docs/chat/#rate-limits); every channel in a comma-separated JOIN counts. Going over gets
/// JOINs dropped silently, so the limit is enforced over a rolling window, with a safety margin by default.
///
/// A channel whose JOIN gets no echo (dropped, or the channel doesn't exist) would otherwise wait forever. After
/// [timeout] it is reported by [takeTimedOut] so the client can queue it again, at most [maxAttempts] times until
/// [reset] (a reconnect) gives every channel a fresh start.
///
/// The clock is injectable so the class can be tested without waiting.
class JoinScheduler {
  final int limit;
  final Duration window;
  final Duration timeout;
  final int maxAttempts;
  final DateTime Function() _now;

  /// When each JOIN in the current window was sent, oldest first.
  final Queue<DateTime> _sent = Queue();

  /// Channels whose JOIN is still unanswered, with the time it was sent.
  final Map<String, DateTime> _pending = {};

  /// JOINs sent per channel since the last [reset] or echo.
  final Map<String, int> _attempts = {};

  JoinScheduler({
    this.limit = 18,
    this.window = const Duration(seconds: 10),
    this.timeout = const Duration(seconds: 20),
    this.maxAttempts = 3,
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
    }
  }

  /// Twitch echoed the JOIN for [channel].
  void acknowledged(String channel) {
    _pending.remove(channel);
    _attempts.remove(channel);
  }

  /// Whether [channel] may be sent another JOIN after a timeout.
  bool canRetry(String channel) => (_attempts[channel] ?? 0) < maxAttempts;

  /// The channels whose JOIN has been unanswered for longer than [timeout]. They stop being pending.
  List<String> takeTimedOut() {
    final cutoff = _now().subtract(timeout);
    final timedOut = [
      for (final entry in _pending.entries)
        if (!entry.value.isAfter(cutoff)) entry.key,
    ];
    timedOut.forEach(_pending.remove);
    return timedOut;
  }

  /// Forgets pending JOINs and retry counts, e.g. after a reconnect. The rate window is kept: the limit is per user,
  /// not per connection.
  void reset() {
    _pending.clear();
    _attempts.clear();
  }
}
