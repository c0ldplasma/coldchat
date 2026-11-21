import 'dart:io';

import 'package:coldchat/data/notifications_cubit.dart';
import 'package:coldchat/data/settings/message_appearance.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:coldchat/tmi/badges.dart';
import 'package:coldchat/tmi/cache.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/emotes.dart';
import 'package:coldchat/widgets/avatar_button.dart';
import 'package:coldchat/widgets/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

/// Just what a [Channel] and its [ChatView] read from the client. The real [Client] opens connections and timers.
class _FakeClient implements Client {
  @override
  Emotes globalEmotes = Emotes();
  @override
  Badges globalBadges = Badges();
  @override
  Emotes twitchUserEmotes = Emotes();
  @override
  EmoteBadgeCache? cache;

  @override
  Future<void> ensureRecentMessages(Channel channel) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Message number [i] in `#ronni`, sent [i] minutes after the first.
ChannelMessageChat _message(int i) => ChannelMessageChat(
  message: irc.Message.fromEvent(
    '@display-name=Ronni;id=message-$i;user-id=1337 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :message $i',
  ),
  dateTime: DateTime(2026, 11, 20).add(Duration(minutes: i)),
);

void main() {
  group('chatListTopPadding', () {
    test('keeps 8 px below the given inset until the overlay is measured', () {
      expect(chatListTopPadding(insetTop: 47.0, overlayHeight: 0.0), 55.0);
      expect(chatListTopPadding(insetTop: 0.0, overlayHeight: 0.0), 8.0);
    });

    test('reaches below the floating search bar and avatar once they are measured', () {
      expect(chatListTopPadding(insetTop: 47.0, overlayHeight: 47.0 + 64.0), 111.0);
      expect(chatListTopPadding(insetTop: 0.0, overlayHeight: 56.0), 56.0);
    });
  });

  group('ChatView', () {
    late Directory tempDir;

    setUpAll(() async {
      Hive.registerAdapters();
      tempDir = Directory.systemTemp.createTempSync('coldchat_chat_view_test');
      Hive.init(tempDir.path);
      final settings = await Hive.openBox<dynamic>('Settings');
      await settings.put('messageAppearance', MessageAppearance());
      await Hive.openBox<dynamic>('AccountSettings');
      await Hive.openBox<dynamic>('TwitchAccounts');
    });

    tearDownAll(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    const statusBar = 47.0;

    /// Shows a chat of 100 messages like the channel view does (with the status bar as its padding) or like the user
    /// card does (filtered, without padding), scrolls it all the way up and returns the oldest message.
    Future<Finder> scrollToOldest(WidgetTester tester, {required bool filtered}) async {
      final channel = Channel(client: _FakeClient(), name: '#ronni');
      addTearDown(channel.close);
      final notifications = NotificationsCubit();
      addTearDown(notifications.close);
      final messages = [for (var i = 0; i < 100; i++) _message(i)];
      messages.forEach(channel.channelMessages.add);

      await tester.pumpWidget(
        BlocProvider<NotificationsCubit>.value(
          value: notifications,
          child: MaterialApp(
            theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(800.0, 600.0),
                padding: EdgeInsets.only(top: statusBar),
                viewPadding: EdgeInsets.only(top: statusBar),
              ),
              child: Material(
                child: filtered
                    ? ChatView(channel: channel, filter: (_) => true)
                    : ChatView(
                        channel: channel,
                        padding: const EdgeInsets.only(top: statusBar),
                      ),
              ),
            ),
          ),
        ),
      );
      // The overlay's height is applied in the frame after it was measured.
      await tester.pump();

      final list = tester.state<ScrollableState>(
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
      );
      list.position.jumpTo(list.position.maxScrollExtent);
      await tester.pump();

      final oldest = find.byKey(ObjectKey(messages.first));
      expect(oldest, findsOneWidget);
      return oldest;
    }

    /// Lets the timer that hides the search bar run out, so the test ends without pending timers.
    Future<void> finish(WidgetTester tester) => tester.pump(const Duration(seconds: 10));

    testWidgets('scrolled all the way up, the oldest message is below the search bar and the avatar', (tester) async {
      final oldest = await scrollToOldest(tester, filtered: false);

      final top = tester.getTopLeft(oldest).dy;
      expect(top, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TextField)).dy));
      expect(top, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AvatarButton)).dy));
      await finish(tester);
    });

    testWidgets('in the user card (filtered, no avatar) the oldest message is below the search bar', (tester) async {
      final oldest = await scrollToOldest(tester, filtered: true);

      expect(find.byType(AvatarButton), findsNothing);
      expect(tester.getTopLeft(oldest).dy, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TextField)).dy));
      await finish(tester);
    });
  });
}
