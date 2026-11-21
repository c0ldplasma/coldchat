import 'dart:io';

import 'package:coldchat/components/bottom_bar.dart';
import 'package:coldchat/data/emote_button_icon.dart';
import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/notifications_cubit.dart';
import 'package:coldchat/data/repositories/account_repository.dart';
import 'package:coldchat/data/repositories/custom_command_repository.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/data/settings/chat_settings.dart';
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
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/emotes.dart';
import 'package:coldchat/widgets/channel_view.dart';
import 'package:coldchat/widgets/chat_message.dart';
import 'package:coldchat/widgets/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

/// Just what a [Channel] and its [ChannelView] read from the client. The real [Client] opens connections and timers.
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
  final Connection transmitter;

  _FakeClient(this.transmitter);

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

const _statusBar = 47.0;

void main() {
  late Directory tempDir;
  // Made outside the tests' fake time: a connection starts a periodic watchdog the tests would report as pending.
  late Connection transmitter;

  setUpAll(() async {
    transmitter = Connection(name: 'transmitter');
    Hive.registerAdapters();
    tempDir = Directory.systemTemp.createTempSync('coldchat_channel_view_test');
    Hive.init(tempDir.path);
    final settings = await Hive.openBox<dynamic>('Settings');
    // Stored up front: a setting read for the first time is written to the box, and a write started in a test's fake
    // time never finishes, which would keep Hive from closing.
    await settings.put(SettingsRepository.messageAppearanceKey, MessageAppearance());
    await settings.put(SettingsRepository.chatSettingsKey, ChatSettings());
    await Hive.openBox<dynamic>('AccountSettings');
    await Hive.openBox<dynamic>('TwitchAccounts');
    await Hive.openBox<dynamic>(CustomCommandRepository.boxName);
  });

  tearDownAll(() async {
    await transmitter.close();
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  /// Shows a [ChannelView] with 20 messages under a [MediaQuery] taken from [mediaQuery], which the test changes to
  /// open the keyboard or move the status bar.
  Future<void> showChannel(WidgetTester tester, ValueNotifier<MediaQueryData> mediaQuery) async {
    final client = _FakeClient(transmitter);
    final channel = Channel(client: client, name: '#ronni');
    addTearDown(channel.close);
    final notifications = NotificationsCubit();
    addTearDown(notifications.close);
    final uploads = UploadQueueCubit();
    addTearDown(uploads.close);
    for (var i = 0; i < 20; i++) {
      channel.channelMessages.add(_message(i));
    }
    final settings = SettingsRepository(Hive.box<dynamic>('Settings'));

    // Created once, like the home page's tabs: only what depends on the media query may rebuild when it changes.
    final channelView = ChannelView(channel: channel);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsRepository>.value(value: settings),
          Provider<AccountRepository>.value(
            value: AccountRepository(Hive.box<dynamic>('TwitchAccounts'), Hive.box<dynamic>('AccountSettings')),
          ),
          Provider<CustomCommandRepository>.value(
            value: CustomCommandRepository(Hive.box<dynamic>(CustomCommandRepository.boxName)),
          ),
          Provider<EmoteButtonIcon>.value(value: EmoteButtonIcon(settings)),
          BlocProvider<NotificationsCubit>.value(value: notifications),
          BlocProvider<UploadQueueCubit>.value(value: uploads),
        ],
        child: MaterialApp(
          theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ValueListenableBuilder<MediaQueryData>(
            valueListenable: mediaQuery,
            builder: (context, data, child) => MediaQuery(data: data, child: child!),
            child: Material(child: channelView),
          ),
        ),
      ),
    );
    // The chat's overlay height is applied in the frame after it was measured.
    await tester.pump();
  }

  /// Lets the timer that hides the chat's search bar run out, so the test ends without pending timers.
  Future<void> finish(WidgetTester tester) => tester.pump(const Duration(seconds: 10));

  Finder chatList() => find.descendant(of: find.byType(ChatView), matching: find.byType(ListView));
  Finder composer() => find.descendant(of: find.byType(BottomBar), matching: find.byType(TextField));

  ValueNotifier<MediaQueryData> statusBarOnly() => ValueNotifier(
    const MediaQueryData(
      size: Size(400.0, 800.0),
      padding: EdgeInsets.only(top: _statusBar),
      viewPadding: EdgeInsets.only(top: _statusBar),
    ),
  );

  testWidgets('typing in the composer does not rebuild the chat list or its messages', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);

    final list = tester.widget(chatList());
    final messages = tester.widgetList(find.byType(ChatMessage)).toList();
    expect(messages, isNotEmpty);

    await tester.enterText(composer(), 'h');
    await tester.pump();
    await tester.enterText(composer(), 'hi');
    await tester.pump();

    expect(find.text('hi'), findsOneWidget);
    // Flutter only skips a subtree when it gets the identical widget again; a rebuilt chat makes new ones.
    expect(identical(tester.widget(chatList()), list), isTrue);
    final messagesAfter = tester.widgetList(find.byType(ChatMessage)).toList();
    expect(messagesAfter, hasLength(messages.length));
    for (var i = 0; i < messages.length; i++) {
      expect(identical(messagesAfter[i], messages[i]), isTrue);
    }
    await finish(tester);
  });

  testWidgets('the keyboard opening does not rebuild the chat list', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    final list = tester.widget(chatList());

    // A few frames of the keyboard sliding in.
    for (final inset in [80.0, 160.0, 240.0, 300.0]) {
      mediaQuery.value = mediaQuery.value.copyWith(viewInsets: EdgeInsets.only(bottom: inset));
      await tester.pump();
    }

    expect(identical(tester.widget(chatList()), list), isTrue);
    await finish(tester);
  });

  testWidgets('the chat still gets the view padding, and follows it when it changes', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    expect(tester.widget<ChatView>(find.byType(ChatView)).padding, const EdgeInsets.only(top: _statusBar));

    mediaQuery.value = mediaQuery.value.copyWith(viewPadding: const EdgeInsets.only(top: 59.0));
    await tester.pump();

    expect(tester.widget<ChatView>(find.byType(ChatView)).padding, const EdgeInsets.only(top: 59.0));
    await finish(tester);
  });
}
