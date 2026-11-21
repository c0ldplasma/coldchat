import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatColors', () {
    test('two built from the same scheme are equal', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark);
      final a = ChatColors.from(scheme);
      final b = ChatColors.from(scheme);
      expect(identical(a, b), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differ when a color differs', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark);
      final a = ChatColors.from(scheme);
      expect(a == a.copyWith(link: Colors.red), isFalse);
      expect(a == a.copyWith(brightness: Brightness.light), isFalse);
    });

    test('an unchanged rebuilt theme compares equal', () {
      const accent = ColdChatTheme.defaultAccent;
      expect(
        ColdChatTheme.build(accent, Brightness.dark, oledBlack: true),
        equals(ColdChatTheme.build(accent, Brightness.dark, oledBlack: true)),
      );
      expect(
        ColdChatTheme.build(accent, Brightness.dark) == ColdChatTheme.build(accent, Brightness.dark, oledBlack: true),
        isFalse,
      );
    });
  });
}
