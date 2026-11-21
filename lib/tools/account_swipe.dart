/// Which way a vertical swipe on the avatar button moves through the saved accounts.
enum AccountSwipe {
  /// Swiped up: the next saved account.
  next,

  /// Swiped down: the previous saved account.
  previous,
}

/// How far (logical pixels) a drag has to move, counted from where the finger went down, to switch accounts.
const double accountSwipeMinDistance = 12.0;

/// How fast (logical pixels per second) a short flick has to be to switch accounts when it moved less than
/// [accountSwipeMinDistance].
const double accountSwipeMinVelocity = 300.0;

/// The direction of a finished vertical drag, from the distance it moved in total ([totalDy], negative is up) and its
/// speed when the finger lifted ([velocityDy]). Returns null when the drag was too short and too slow to count.
///
/// The total distance decides, not the last movement before lifting: a finger usually slows down or wobbles at the
/// end of a swipe.
AccountSwipe? accountSwipeFor({required double totalDy, required double velocityDy}) {
  if (totalDy.abs() >= accountSwipeMinDistance) {
    return totalDy < 0 ? AccountSwipe.next : AccountSwipe.previous;
  }
  if (velocityDy.abs() >= accountSwipeMinVelocity) {
    return velocityDy < 0 ? AccountSwipe.next : AccountSwipe.previous;
  }
  return null;
}

/// The index of the account to switch to among [count] saved accounts, when [current] is the active one's index (-1
/// when no saved account is active). Wraps around at both ends. Returns null when there is nothing to switch to.
int? swipedAccountIndex({required int current, required int count, required AccountSwipe swipe}) {
  if (count <= 0) return null;
  final int next;
  if (current < 0 || current >= count) {
    next = swipe == AccountSwipe.next ? 0 : count - 1;
  } else {
    next = (current + (swipe == AccountSwipe.next ? 1 : -1)) % count;
  }
  return next == current ? null : next;
}
