import 'dart:io';

import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:coldchat/widgets/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../tmi/channel_message_chat_test.dart' show chat;

late SettingsRepository settings;

Widget app(Widget child) => Provider<SettingsRepository>.value(
  value: settings,
  child: MaterialApp(
    theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  late Directory tempDir;

  setUpAll(() async {
    Hive.registerAdapters();
    tempDir = Directory.systemTemp.createTempSync('coldchat_chat_message_test');
    Hive.init(tempDir.path);
    settings = await SettingsRepository.open();
    // Without timestamps and badges the user name is the first thing in the message's text.
    await settings.saveMessageAppearance(
      settings.messageAppearance
        ..timestamps = false
        ..badges = false,
    );
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('a tap on the user name that ends after the message was replaced does nothing', (tester) async {
    await tester.pumpWidget(app(ChatMessage(key: const ValueKey(1), message: chat('first'))));

    final name = tester.getTopLeft(find.byType(RichText).first) + const Offset(4.0, 4.0);
    final gesture = await tester.startGesture(name);

    // A pending message replaced by the sent one gets a new element (they're keyed by message), like this.
    await tester.pumpWidget(app(ChatMessage(key: const ValueKey(2), message: chat('second'))));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
