import 'package:coldchat/tmi/client/join_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late JoinScheduler joins;

  void advance(Duration duration) => now = now.add(duration);
  List<String> names(int count, [String prefix = '#c']) => [for (var i = 0; i < count; i++) '$prefix$i'];

  setUp(() {
    now = DateTime(2026, 11, 21, 12);
    joins = JoinScheduler(now: () => now);
  });

  group('rate limit', () {
    test('allows 18 JOINs in a fresh window by default', () {
      expect(joins.available, 18);
    });

    test('counts every channel of a JOIN', () {
      joins.sent(names(12));
      expect(joins.available, 6);
    });

    test('the old 12 + 4 every 2 s schedule stays within 20 JOINs per 10 s', () {
      var sentInWindow = 0;
      for (var tick = 0; tick < 5; tick++) {
        final batch = joins.available.clamp(0, tick == 0 ? 12 : 4);
        joins.sent(names(batch, '#t$tick-'));
        sentInWindow += batch;
        advance(const Duration(seconds: 2));
      }
      expect(sentInWindow, 18);
      expect(sentInWindow, lessThanOrEqualTo(20));
    });

    test('frees a slot only once its JOIN is a full window old', () {
      joins.sent(names(18));
      expect(joins.available, 0);
      advance(const Duration(seconds: 9, milliseconds: 999));
      expect(joins.available, 0);
      advance(const Duration(milliseconds: 1));
      expect(joins.available, 18);
    });

    test('is a rolling window, not fixed buckets', () {
      joins.sent(names(10, '#a'));
      advance(const Duration(seconds: 6));
      joins.sent(names(8, '#b'));
      expect(joins.available, 0);
      advance(const Duration(seconds: 4));
      expect(joins.available, 10);
      advance(const Duration(seconds: 6));
      expect(joins.available, 18);
    });

    test('never allows more than the limit in any 10 s span', () {
      final sentAt = <DateTime>[];
      for (var tick = 0; tick < 60; tick++) {
        final batch = joins.available.clamp(0, 4);
        joins.sent(names(batch, '#t$tick-'));
        sentAt.addAll(List.filled(batch, now));
        advance(const Duration(milliseconds: 700));
      }
      for (final start in sentAt) {
        final inWindow = sentAt.where((t) => !t.isBefore(start) && t.difference(start) < const Duration(seconds: 10));
        expect(inWindow.length, lessThanOrEqualTo(18));
      }
    });

    test('reset keeps the rate window', () {
      joins.sent(names(18));
      joins.reset();
      expect(joins.available, 0);
    });

    test('limit and window are configurable', () {
      joins = JoinScheduler(limit: 2, window: const Duration(seconds: 1), now: () => now);
      joins.sent(['#a', '#b']);
      expect(joins.available, 0);
      advance(const Duration(seconds: 1));
      expect(joins.available, 2);
    });
  });

  group('unanswered JOINs', () {
    test('time out after 20 s by default', () {
      joins.sent(['#a']);
      advance(const Duration(seconds: 19));
      expect(joins.takeTimedOut(), isEmpty);
      advance(const Duration(seconds: 1));
      expect(joins.takeTimedOut(), ['#a']);
      expect(joins.takeTimedOut(), isEmpty, reason: 'a timed out channel is reported once');
    });

    test('an echoed JOIN never times out', () {
      joins.sent(['#a', '#b']);
      joins.acknowledged('#a');
      advance(const Duration(minutes: 1));
      expect(joins.takeTimedOut(), ['#b']);
    });

    test('a timed out channel can be joined again right away for its first three JOINs', () {
      for (var attempt = 1; attempt <= 3; attempt++) {
        expect(joins.canJoin('#missing'), isTrue);
        joins.sent(['#missing']);
        expect(joins.canJoin('#missing'), isFalse, reason: 'pending');
        expect(joins.isDue('#missing'), isFalse);
        advance(const Duration(seconds: 20));
        expect(joins.takeTimedOut(), ['#missing']);
        if (attempt < 3) {
          expect(joins.isDue('#missing'), isTrue);
          expect(joins.canJoin('#missing'), isTrue);
        }
      }
    });

    test('after three unanswered JOINs the delay starts at 30 s and doubles up to 5 minutes', () {
      final delays = <Duration>[];
      for (var attempt = 1; attempt <= 9; attempt++) {
        joins.sent(['#missing']);
        advance(const Duration(seconds: 20));
        expect(joins.takeTimedOut(), ['#missing']);
        delays.add(joins.retryDelay('#missing'));
        final delay = delays.last;
        if (delay > Duration.zero) {
          advance(delay - const Duration(milliseconds: 1));
          expect(joins.isDue('#missing'), isFalse);
          expect(joins.canJoin('#missing'), isFalse);
          advance(const Duration(milliseconds: 1));
        }
        expect(joins.isDue('#missing'), isTrue);
        expect(joins.canJoin('#missing'), isTrue);
      }
      expect(delays.map((delay) => delay.inSeconds), [0, 0, 30, 60, 120, 240, 300, 300, 300]);
    });

    test('backoff is configurable', () {
      joins = JoinScheduler(
        maxAttempts: 1,
        firstBackoff: const Duration(seconds: 5),
        maxBackoff: const Duration(seconds: 8),
        now: () => now,
      );
      final delays = <int>[];
      for (var attempt = 0; attempt < 3; attempt++) {
        joins.sent(['#a']);
        delays.add(joins.retryDelay('#a').inSeconds);
      }
      expect(delays, [5, 8, 8]);
    });

    test('an echo resets the retry count and the delay', () {
      for (var attempt = 0; attempt < 4; attempt++) {
        joins.sent(['#a']);
        advance(const Duration(seconds: 20));
        joins.takeTimedOut();
      }
      expect(joins.canJoin('#a'), isFalse);
      joins.acknowledged('#a');
      expect(joins.canJoin('#a'), isTrue);
      expect(joins.isDue('#a'), isFalse);
      expect(joins.retryDelay('#a'), Duration.zero);
    });

    test('reset forgets pending JOINs, retry counts and delays', () {
      joins.sent(['#a', '#a', '#a']);
      advance(const Duration(seconds: 20));
      joins.takeTimedOut();
      expect(joins.canJoin('#a'), isFalse);
      joins.reset();
      expect(joins.canJoin('#a'), isTrue);
      expect(joins.isDue('#a'), isFalse);
      advance(const Duration(minutes: 1));
      expect(joins.takeTimedOut(), isEmpty);
    });
  });
}
