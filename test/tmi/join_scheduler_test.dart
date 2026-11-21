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

    test('a channel can be retried until it has had three JOINs', () {
      for (var attempt = 1; attempt <= 3; attempt++) {
        expect(joins.canRetry('#missing'), isTrue);
        joins.sent(['#missing']);
        advance(const Duration(seconds: 30));
        expect(joins.takeTimedOut(), ['#missing']);
      }
      expect(joins.canRetry('#missing'), isFalse);
    });

    test('an echo resets the retry count', () {
      joins.sent(['#a']);
      joins.sent(['#a']);
      joins.sent(['#a']);
      expect(joins.canRetry('#a'), isFalse);
      joins.acknowledged('#a');
      expect(joins.canRetry('#a'), isTrue);
    });

    test('reset forgets pending JOINs and retry counts', () {
      joins.sent(['#a', '#a', '#a']);
      joins.reset();
      expect(joins.canRetry('#a'), isTrue);
      advance(const Duration(minutes: 1));
      expect(joins.takeTimedOut(), isEmpty);
    });
  });
}
