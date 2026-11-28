import 'package:coldchat/data/credits.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every credited translation is of a language the app has', () {
    final languages = {for (final locale in AppLocalizations.supportedLocales) locale.languageCode};

    for (final credit in credits) {
      final language = credit.language;
      if (language == null) continue;
      expect(languages, contains(language.split('_').first), reason: '${credit.name} translated $language');
    }
  });
}
