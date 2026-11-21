import 'dart:io';

import 'package:coldchat/data/notifications_cubit.dart';
import 'package:coldchat/data/repositories/account_repository.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/data/settings/message_appearance.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/modal/user.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:coldchat/tmi/badges.dart';
import 'package:coldchat/tmi/cache.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/emotes.dart';
import 'package:coldchat/widgets/avatar_button.dart';
import 'package:coldchat/widgets/chat_message.dart';
import 'package:coldchat/widgets/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

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

  /// Anonymous, so the user card doesn't ask Helix for a profile.
  @override
  TokenData? get apiTokenData => null;

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
    late SettingsRepository settings;

    setUpAll(() async {
      Hive.registerAdapters();
      tempDir = Directory.systemTemp.createTempSync('coldchat_chat_view_test');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>('Settings');
      await Hive.openBox<dynamic>('AccountSettings');
      await Hive.openBox<dynamic>('TwitchAccounts');
      settings = SettingsRepository(Hive.box<dynamic>('Settings'));
    });

    setUp(() async {
      // Without timestamps and badges the user name is the first thing in a message's text.
      await settings.saveMessageAppearance(
        MessageAppearance()
          ..timestamps = false
          ..badges = false,
      );
    });

    tearDownAll(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    const statusBar = 47.0;

    /// A channel with [count] messages, closed after the test.
    (Channel, List<ChannelMessageChat>) channelWith(int count) {
      final channel = Channel(client: _FakeClient(), name: '#ronni');
      addTearDown(channel.close);
      final messages = [for (var i = 0; i < count; i++) _message(i)];
      messages.forEach(channel.channelMessages.add);
      return (channel, messages);
    }

    /// Shows [channel]'s chat like the channel view does (with the status bar as its padding) or like the user card
    /// does (filtered, without padding).
    Future<void> showChat(WidgetTester tester, Channel channel, {bool filtered = false}) async {
      final notifications = NotificationsCubit();
      addTearDown(notifications.close);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsRepository>.value(value: settings),
            Provider<AccountRepository>.value(
              value: AccountRepository(Hive.box<dynamic>('TwitchAccounts'), Hive.box<dynamic>('AccountSettings')),
            ),
            Provider<Client>.value(value: channel.client),
            BlocProvider<NotificationsCubit>.value(value: notifications),
          ],
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
    }

    /// Shows a chat of 100 messages, scrolls it all the way up and returns the oldest message.
    Future<Finder> scrollToOldest(WidgetTester tester, {required bool filtered}) async {
      final (channel, messages) = channelWith(100);
      await showChat(tester, channel, filtered: filtered);

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

    testWidgets('a new message keeps the elements of the messages already shown', (tester) async {
      final (channel, messages) = channelWith(10);
      await showChat(tester, channel);
      final states = {for (final message in messages) message: tester.state(find.byKey(ObjectKey(message)))};

      channel.channelMessages.add(_message(10));
      await tester.pump();

      expect(find.text('Ronni: message 10 ', findRichText: true), findsOneWidget);
      for (final message in messages) {
        expect(tester.state(find.byKey(ObjectKey(message))), same(states[message]));
      }
      await finish(tester);
    });

    testWidgets("a new message doesn't rebuild the messages already shown", (tester) async {
      final (channel, messages) = channelWith(10);
      await showChat(tester, channel);
      final widgets = {for (final message in messages) message: tester.widget(find.byKey(ObjectKey(message)))};

      channel.channelMessages.add(_message(10));
      await tester.pump();

      // The list got the very same widget again, so Flutter didn't build it again.
      for (final message in messages) {
        expect(tester.widget(find.byKey(ObjectKey(message))), same(widgets[message]));
      }
      await finish(tester);
    });

    testWidgets('a tap on a user name opens the user card even when a new message arrives during it', (tester) async {
      final (channel, messages) = channelWith(10);
      await showChat(tester, channel);

      final name = tester.getTopLeft(find.byKey(ObjectKey(messages.last))) + const Offset(16.0, 8.0);
      final gesture = await tester.startGesture(name);
      channel.channelMessages.add(_message(10));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(UserModal), findsOneWidget);
      await finish(tester);
    });

    testWidgets('messages rebuilt in place show their new content after a refresh', (tester) async {
      final (channel, messages) = channelWith(10);
      await showChat(tester, channel);
      expect(find.byType(BlockedChatMessage), findsNothing);

      // Like Channel.rebuildMessages: the message itself changes, then the same messages are emitted again.
      messages.last.blocked = true;
      channel.channelMessages.refresh();
      await tester.pump();

      expect(find.byType(BlockedChatMessage), findsOneWidget);
      await finish(tester);
    });

    testWidgets('the messages shown follow a change of the message appearance', (tester) async {
      final (channel, _) = channelWith(10);
      await showChat(tester, channel);
      expect(find.text('Ronni: message 9 ', findRichText: true), findsOneWidget);

      await tester.runAsync(() => settings.saveMessageAppearance(settings.messageAppearance..timestamps = true));
      await tester.pump();

      expect(find.text('0:09  Ronni: message 9 ', findRichText: true), findsOneWidget);
      await finish(tester);
    });
  });
}
