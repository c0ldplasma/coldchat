import 'package:coldchat/tools/account_swipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('accountSwipeFor', () {
    test('uses the total distance, not the last movement', () {
      // A swipe up that slowed down or wobbled back a little at the end still counts as up.
      expect(accountSwipeFor(totalDy: -40.0, velocityDy: 50.0), AccountSwipe.next);
      expect(accountSwipeFor(totalDy: 40.0, velocityDy: -50.0), AccountSwipe.previous);
    });

    test('a short, fast flick counts by its velocity', () {
      expect(accountSwipeFor(totalDy: -4.0, velocityDy: -800.0), AccountSwipe.next);
      expect(accountSwipeFor(totalDy: 4.0, velocityDy: 800.0), AccountSwipe.previous);
    });

    test('a short, slow drag does nothing', () {
      expect(accountSwipeFor(totalDy: -4.0, velocityDy: -100.0), isNull);
      expect(accountSwipeFor(totalDy: 0.0, velocityDy: 0.0), isNull);
    });

    test('the thresholds are inclusive', () {
      expect(accountSwipeFor(totalDy: -accountSwipeMinDistance, velocityDy: 0.0), AccountSwipe.next);
      expect(accountSwipeFor(totalDy: 0.0, velocityDy: accountSwipeMinVelocity), AccountSwipe.previous);
    });
  });

  group('swipedAccountIndex', () {
    test('moves to the next and previous account', () {
      expect(swipedAccountIndex(current: 1, count: 3, swipe: AccountSwipe.next), 2);
      expect(swipedAccountIndex(current: 1, count: 3, swipe: AccountSwipe.previous), 0);
    });

    test('wraps around at both ends', () {
      expect(swipedAccountIndex(current: 2, count: 3, swipe: AccountSwipe.next), 0);
      expect(swipedAccountIndex(current: 0, count: 3, swipe: AccountSwipe.previous), 2);
    });

    test('with no active account, picks the first or last one', () {
      expect(swipedAccountIndex(current: -1, count: 3, swipe: AccountSwipe.next), 0);
      expect(swipedAccountIndex(current: -1, count: 3, swipe: AccountSwipe.previous), 2);
    });

    test('returns null when there is nothing to switch to', () {
      expect(swipedAccountIndex(current: -1, count: 0, swipe: AccountSwipe.next), isNull);
      expect(swipedAccountIndex(current: 0, count: 1, swipe: AccountSwipe.next), isNull);
      expect(swipedAccountIndex(current: 0, count: 1, swipe: AccountSwipe.previous), isNull);
    });

    test('a single saved account that is not active can be swiped to', () {
      expect(swipedAccountIndex(current: -1, count: 1, swipe: AccountSwipe.next), 0);
    });
  });
}
