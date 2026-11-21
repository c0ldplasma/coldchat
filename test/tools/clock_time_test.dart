import 'package:coldchat/tools/clock_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final evening = DateTime(2026, 11, 21, 21, 5);
  final morning = DateTime(2026, 11, 21, 9, 5);

  Future<MaterialLocalizations> load(String language) => GlobalMaterialLocalizations.delegate.load(Locale(language));

  test('English uses a 12-hour clock', () async {
    final en = await load('en');
    expect(clockTime(evening, en), '9:05 PM');
    expect(clockTime(morning, en), '9:05 AM');
  });

  test('German uses a 24-hour clock', () async {
    final de = await load('de');
    expect(clockTime(evening, de), '21:05');
    expect(clockTime(morning, de), '09:05');
  });

  test("the phone's 24-hour setting wins over the language", () async {
    expect(clockTime(evening, await load('en'), alwaysUse24HourFormat: true), '21:05');
  });

  testWidgets('clockTimeOf reads the language and the 24-hour setting from the context', (tester) async {
    Future<String> render({required bool use24}) async {
      late String text;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(alwaysUse24HourFormat: use24),
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
            child: Builder(
              builder: (context) {
                text = clockTimeOf(context, evening);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return text;
    }

    expect(await render(use24: false), '9:05 PM');
    expect(await render(use24: true), '21:05');
  });
}
