import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/modal/message.dart';
import 'package:coldchat/modal/user.dart';
import 'package:coldchat/tmi/moderation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  test('a failed delete asks to sign in again or shows the reason', () {
    expect(deleteFailureText(l10n, const ModerationNeedsScope()), l10n.deleteMessageNeedsScope);
    expect(deleteFailureText(l10n, const ModerationNeedsLogin()), l10n.deleteMessageNeedsScope);
    expect(deleteFailureText(l10n, const ModerationRequestFailed('nope')), l10n.deleteMessageFailed('nope'));
  });

  test('a failed ban, timeout or unban says what is missing or shows the reason', () {
    expect(moderationFailureText(l10n, const ModerationNeedsLogin()), l10n.moderationNeedsLogin);
    expect(moderationFailureText(l10n, const ModerationNeedsScope()), l10n.moderationNeedsScope);
    expect(moderationFailureText(l10n, const ModerationRequestFailed('nope')), l10n.moderationFailed('nope'));
  });
}
