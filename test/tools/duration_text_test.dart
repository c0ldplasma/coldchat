import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/tools/duration_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));
  final ja = lookupAppLocalizations(const Locale('ja'));

  String format(Duration duration, [AppLocalizations? l10n]) => shortDuration(duration, l10n ?? en);

  test('uses the largest unit', () {
    expect(format(const Duration(seconds: 1)), '1 s');
    expect(format(const Duration(seconds: 59)), '59 s');
    expect(format(const Duration(seconds: 60)), '1 min');
    expect(format(const Duration(minutes: 10)), '10 min');
    expect(format(const Duration(hours: 1)), '1 h');
    expect(format(const Duration(days: 1)), '1 d');
    expect(format(const Duration(days: 14)), '14 d');
  });

  test('adds the next smaller unit when it is not zero', () {
    expect(format(const Duration(seconds: 90)), '1 min 30 s');
    expect(format(const Duration(hours: 1, minutes: 30)), '1 h 30 min');
    expect(format(const Duration(days: 1, hours: 2)), '1 d 2 h');
  });

  test('leaves out anything smaller than two units', () {
    expect(format(const Duration(hours: 1, seconds: 5)), '1 h');
    expect(format(const Duration(hours: 1, minutes: 30, seconds: 45)), '1 h 30 min');
    expect(format(const Duration(days: 1, minutes: 5)), '1 d');
  });

  test('reads zero and negative durations as 0 s', () {
    expect(format(Duration.zero), '0 s');
    expect(format(const Duration(seconds: -5)), '0 s');
    expect(format(const Duration(milliseconds: 500)), '0 s');
  });

  test('is localized', () {
    expect(format(const Duration(seconds: 1), de), '1 Sek.');
    expect(format(const Duration(hours: 1, minutes: 30), de), '1 Std. 30 Min.');
    expect(format(const Duration(days: 14), de), '14 Tg.');
    expect(format(const Duration(hours: 1, minutes: 30), ja), '1時間30分');
    expect(de.bannedForDuration(format(const Duration(seconds: 1), de)), 'für 1 Sek. gesperrt');
  });
}
