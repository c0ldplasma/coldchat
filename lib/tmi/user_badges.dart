import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';

import '../data/badge_users.dart';
import '../data/custom_badge.dart';

/// The global third-party badges (7TV, BTTV, FFZ, DankChat) and the users who have them.
///
/// The sources list users per badge; [badgesOf] answers the other way round, which is what every chat message
/// asks. The index is rebuilt on every new state, so a user who gains or loses a badge gets the new set on their
/// next message.
class UserBadges extends Cubit<List<BadgeUsers>> {
  UserBadges() : super([]);

  Map<String, List<CustomBadge>> _byUser = const {};

  void change(List<BadgeUsers> badges) {
    emit(badges);
  }

  @override
  void emit(List<BadgeUsers> state) {
    _byUser = _index(state);
    super.emit(state);
  }

  /// The badges of [userId], in the order of [state]; each badge at most once.
  List<CustomBadge> badgesOf(String userId) => _byUser[userId] ?? const [];

  /// Whether [a] and [b] give every user the same badges: same badges in the same order, with the same users.
  /// Comparing only the number of users would miss one user losing a badge while another gains it.
  static bool sameHolders(List<BadgeUsers> a, List<BadgeUsers> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].badge.id != b[i].badge.id || a[i].badge.source.name != b[i].badge.source.name) return false;
      if (!const SetEquality<String>().equals(a[i].users.toSet(), b[i].users.toSet())) return false;
    }
    return true;
  }

  static Map<String, List<CustomBadge>> _index(List<BadgeUsers> badges) {
    final byUser = <String, List<CustomBadge>>{};
    for (final badgeUsers in badges) {
      for (final userId in badgeUsers.users.toSet()) {
        (byUser[userId] ??= []).add(badgeUsers.badge);
      }
    }
    return byUser;
  }
}
