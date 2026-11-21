import 'package:coldchat/data/badge_users.dart';
import 'package:coldchat/data/custom_badge.dart';
import 'package:coldchat/providers/provider.dart';
import 'package:coldchat/tmi/user_badges.dart';
import 'package:flutter_test/flutter_test.dart';

class _Provider implements Provider {
  _Provider(this.name);

  @override
  final String name;

  @override
  String? get description => null;
}

CustomBadge badge(String id, {String provider = '7TV'}) =>
    CustomBadge(id: id, name: id, mipmap: const [], provider: _Provider(provider));

BadgeUsers holders(CustomBadge badge, List<String> users) => BadgeUsers(badge: badge, users: users);

void main() {
  final staff = badge('staff');
  final supporter = badge('supporter', provider: 'FFZ');
  final pro = badge('pro', provider: 'BTTV');

  group('badgesOf', () {
    test('is empty before any badges are loaded and for users without one', () {
      final badges = UserBadges();
      expect(badges.badgesOf('1'), isEmpty);

      badges.change([
        holders(staff, ['1']),
      ]);
      expect(badges.badgesOf('2'), isEmpty);
    });

    test('lists all badges of a user in the order of the state', () {
      final badges = UserBadges()
        ..change([
          holders(staff, ['1', '2']),
          holders(supporter, ['2']),
          holders(pro, ['2', '3']),
        ]);

      expect(badges.badgesOf('1'), [staff]);
      expect(badges.badgesOf('2'), [staff, supporter, pro]);
      expect(badges.badgesOf('3'), [pro]);
    });

    test('lists a badge once when a provider names the user twice', () {
      final badges = UserBadges()
        ..change([
          holders(staff, ['1', '1']),
        ]);

      expect(badges.badgesOf('1'), [staff]);
    });

    test('follows a new state: a user who gains or loses a badge gets the new set', () {
      final badges = UserBadges()
        ..change([
          holders(staff, ['1']),
          holders(supporter, ['2']),
        ]);

      badges.change([
        holders(staff, ['2']),
        holders(supporter, ['2']),
      ]);

      expect(badges.badgesOf('1'), isEmpty);
      expect(badges.badgesOf('2'), [staff, supporter]);
    });
  });

  group('sameHolders', () {
    test('is true for the same badges and users, in any user order', () {
      expect(
        UserBadges.sameHolders(
          [
            holders(staff, ['1', '2']),
          ],
          [
            holders(staff, ['2', '1']),
          ],
        ),
        isTrue,
      );
    });

    test('is false when one user loses a badge and another gains it', () {
      expect(
        UserBadges.sameHolders(
          [
            holders(staff, ['1']),
          ],
          [
            holders(staff, ['2']),
          ],
        ),
        isFalse,
      );
    });

    test('is false when a badge is added, removed or from another provider', () {
      expect(
        UserBadges.sameHolders([], [
          holders(staff, ['1']),
        ]),
        isFalse,
      );
      expect(
        UserBadges.sameHolders([
          holders(staff, ['1']),
        ], []),
        isFalse,
      );
      expect(
        UserBadges.sameHolders(
          [
            holders(staff, ['1']),
          ],
          [
            holders(badge('staff', provider: 'FFZ'), ['1']),
          ],
        ),
        isFalse,
      );
    });
  });
}
