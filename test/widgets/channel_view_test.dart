import 'dart:async';
import 'dart:io';

import 'package:coldchat/components/bottom_bar.dart';
import 'package:coldchat/components/modal.dart';
import 'package:coldchat/components/tile.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/data/emote_button_icon.dart';
import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/notifications_cubit.dart';
import 'package:coldchat/data/repositories/account_repository.dart';
import 'package:coldchat/data/repositories/channel_repository.dart';
import 'package:coldchat/data/repositories/custom_command_repository.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/data/settings/chat_settings.dart';
import 'package:coldchat/data/settings/message_appearance.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/data/twitch_account.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/l10n/app_localizations.dart';
import 'package:coldchat/pages/home.dart';
import 'package:coldchat/sheets/message.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:coldchat/tmi/connection/connection_state.dart' as tmi;
import 'package:coldchat/widgets/channel_view.dart';
import 'package:coldchat/widgets/chat_message.dart';
import 'package:coldchat/widgets/chat_view.dart';
import 'package:coldchat/widgets/logged_out_start.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../api/fake_api.dart';
import '../tmi/client/fake_client.dart';

/// Only the last shown channel, kept in memory.
class _FakeChannelRepository implements ChannelRepository {
  @override
  String? lastChannel;

  _FakeChannelRepository(this.lastChannel);

  @override
  Future<void> setLastChannel(String name) async => lastChannel = name;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Message number [i] in `#ronni`, sent [i] minutes after the first, in [channel] if given (the message sheet acts on
/// it).
ChannelMessageChat _message(int i, [Channel? channel]) => ChannelMessageChat(
  message: irc.Message.fromEvent(
    '@display-name=Ronni;id=message-$i;user-id=1337 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :message $i',
  ),
  dateTime: DateTime(2026, 11, 20).add(Duration(minutes: i)),
  channel: channel,
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
    // Past the start screen of a fresh install, so the home page shows its tabs.
    await settings.put(SettingsRepository.startScreenDoneKey, true);
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
  Future<Channel> showChannel(WidgetTester tester, ValueNotifier<MediaQueryData> mediaQuery) async {
    final client = FakeClient(transmitter: transmitter);
    final channel = Channel(client: client, name: '#ronni');
    addTearDown(channel.close);
    final notifications = NotificationsCubit();
    addTearDown(notifications.close);
    final uploads = UploadQueueCubit(api: offlineApi());
    addTearDown(uploads.close);
    for (var i = 0; i < 20; i++) {
      channel.channelMessages.add(_message(i, channel));
    }
    final settings = SettingsRepository(Hive.box<dynamic>('Settings'));

    // Created once, like the home page's tabs: only what depends on the media query may rebuild when it changes.
    final channelView = ChannelView(channel: channel);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<Client>.value(value: client),
          Provider<SettingsRepository>.value(value: settings),
          Provider<AccountRepository>.value(
            value: AccountRepository(Hive.box<dynamic>('TwitchAccounts'), Hive.box<dynamic>('AccountSettings')),
          ),
          Provider<CustomCommandRepository>.value(
            value: CustomCommandRepository(Hive.box<dynamic>(CustomCommandRepository.boxName)),
          ),
          Provider<EmoteButtonIcon>.value(value: EmoteButtonIcon(settings, api: offlineApi())),
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
    return channel;
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

  /// Opens the message sheet of the newest message on screen, as a long press does, and taps [action] in it.
  Future<void> tapInMessageSheet(WidgetTester tester, String action) async {
    await tester.longPress(find.byType(ChatMessage).hitTestable().last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  testWidgets('Reply in the message sheet shows the message above the composer and the close button removes it', (
    tester,
  ) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    final channel = await showChannel(tester, mediaQuery);
    final l10n = AppLocalizations.of(tester.element(composer()));
    expect(find.text(l10n.replyingTo), findsNothing);

    await tapInMessageSheet(tester, l10n.reply);

    expect(find.text(l10n.replyingTo), findsOneWidget);
    expect(
      channel.composerDraft.state,
      same(tester.widget<ChatMessage>(find.byType(ChatMessage).hitTestable().last).message),
    );

    await tester.tap(find.byIcon(Icons.close_outlined));
    await tester.pump();
    expect(find.text(l10n.replyingTo), findsNothing);
    expect(channel.composerDraft.state, isNull);
    await finish(tester);
  });

  testWidgets('Mention in the message sheet appends @login to what is typed in the composer', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    final l10n = AppLocalizations.of(tester.element(composer()));
    await tester.enterText(composer(), 'hi ');
    await tester.pump();

    await tapInMessageSheet(tester, l10n.mentionUser);

    expect(tester.widget<TextField>(composer()).controller!.text, 'hi @ronni');
    await finish(tester);
  });

  testWidgets('sending without picking a suggestion closes the suggestions', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    final channel = await showChannel(tester, mediaQuery);
    (channel.client as FakeClient).globals.emotes.change([
      Emote(id: 'pog', name: 'PogChamp', mipmap: ['https://example.com/pog'], source: _TestSource()),
    ]);
    await tester.runAsync(() async {
      transmitter.add(ConnectionEstablished(tmi.ConnectionConnected(_account)));
      await transmitter.stream.firstWhere((state) => state is tmi.ConnectionConnected);
    });
    channel.transmitterJoin.joined();
    await tester.pump();
    Finder suggestion(String title) => find.descendant(of: find.byType(Tile), matching: find.text(title));

    // An emote, and Ronni because they wrote in the chat.
    for (final (typed, title) in [('hi Pog', 'PogChamp'), ('hi ro', 'Ronni')]) {
      await tester.enterText(composer(), typed);
      await tester.pump();
      expect(suggestion(title), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(tester.widget<TextField>(composer()).controller!.text, isEmpty);
      expect(suggestion(title), findsNothing);
    }

    // The transmitter is shared by every test here: leave it disconnected again, as the next test expects.
    channel.transmitterJoin.parted();
    await tester.runAsync(() async {
      transmitter.add(ConnectionDisconnect());
      await transmitter.stream.firstWhere((state) => state is tmi.ConnectionDisconnected);
    });
    await finish(tester);
  });

  testWidgets('the composer says it is connecting until the channel can be written to', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    final channel = await showChannel(tester, mediaQuery);
    final l10n = AppLocalizations.of(tester.element(composer()));
    String? hint() => tester.widget<TextField>(composer()).decoration!.hintText;
    expect(hint(), l10n.channelConnecting('#ronni'));

    await tester.runAsync(() async {
      transmitter.add(ConnectionEstablished(tmi.ConnectionConnected(_account)));
      await transmitter.stream.firstWhere((state) => state is tmi.ConnectionConnected);
    });
    channel.transmitterJoin.joined();
    await tester.pump();
    expect(hint(), l10n.sendMessageIn('#ronni'));

    channel.transmitterJoin.parted();
    await tester.pump();
    expect(hint(), l10n.channelConnecting('#ronni'));

    await tester.runAsync(() async {
      transmitter.add(ConnectionDisconnect());
      await transmitter.stream.firstWhere((state) => state is tmi.ConnectionDisconnected);
    });
    await finish(tester);
  });
  group('from a message sheet of another channel', () {
    late FakeClient client;
    late Channel a;
    late Channel b;

    /// The home page with the tabs of `#a` and `#b`, showing `#a`. `#b` has 3 messages.
    Future<void> showHome(WidgetTester tester) async {
      client = FakeClient(transmitter: transmitter);
      addTearDown(client.closeFocusRequests);
      addTearDown(client.whispers.close);
      a = Channel(client: client, name: '#a');
      b = Channel(client: client, name: '#b');
      addTearDown(a.close);
      addTearDown(b.close);
      (client.channels as FakeChannels).show([a, b]);
      addTearDown(client.channels.close);
      for (var i = 0; i < 3; i++) {
        b.channelMessages.add(_message(i, b));
      }
      final notifications = NotificationsCubit();
      addTearDown(notifications.close);
      final uploads = UploadQueueCubit(api: offlineApi());
      addTearDown(uploads.close);
      final settings = SettingsRepository(Hive.box<dynamic>('Settings'));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<Client>.value(value: client),
            Provider<ChannelRepository>.value(value: _FakeChannelRepository('#a')),
            Provider<SettingsRepository>.value(value: settings),
            Provider<AccountRepository>.value(
              value: AccountRepository(Hive.box<dynamic>('TwitchAccounts'), Hive.box<dynamic>('AccountSettings')),
            ),
            Provider<CustomCommandRepository>.value(
              value: CustomCommandRepository(Hive.box<dynamic>(CustomCommandRepository.boxName)),
            ),
            Provider<EmoteButtonIcon>.value(value: EmoteButtonIcon(settings, api: offlineApi())),
            BlocProvider<NotificationsCubit>.value(value: notifications),
            BlocProvider<UploadQueueCubit>.value(value: uploads),
          ],
          child: MaterialApp(
            theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a fresh install shows only the start screen, until "Continue without logging in"', (tester) async {
      await tester.runAsync(() => Hive.box<dynamic>('Settings').delete(SettingsRepository.startScreenDoneKey));
      await showHome(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(LoggedOutStart)));
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(ChannelView), findsNothing);

      // In real time: a write to the settings box started in the test's fake time never finishes, and Hive would wait
      // for it when closing.
      await tester.runAsync(() async {
        await tester.tap(find.text(l10n.continueWithoutLogin));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.byType(LoggedOutStart), findsNothing);
      expect(find.byType(TabBar), findsOneWidget);
      expect(SettingsRepository(Hive.box<dynamic>('Settings')).startScreenDone, isTrue);
    });

    Channel shownChannel(WidgetTester tester) => tester.widget<ChannelView>(find.byType(ChannelView)).channel;

    /// Opens the message sheet of `#b`'s newest message from `#a`'s view, as the notifications sheet does, and taps
    /// [action] in it.
    Future<void> tapInSheetOfB(WidgetTester tester, String action) async {
      unawaited(
        Modal.show(
          context: tester.element(find.byType(ChannelView)),
          child: MessageModal(message: b.channelMessages.state.whereType<ChannelMessageChat>().last),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
    }

    testWidgets('Reply switches to the message\'s channel and shows the reply bar there', (tester) async {
      await showHome(tester);
      expect(shownChannel(tester), a);
      final l10n = AppLocalizations.of(tester.element(composer()));

      await tapInSheetOfB(tester, l10n.reply);

      expect(find.byType(MessageModal), findsNothing);
      expect(shownChannel(tester), b);
      expect(find.text(l10n.replyingTo), findsOneWidget);
      expect(b.composerDraft.state?.id, 'message-2');
      expect(a.composerDraft.state, isNull);
      await finish(tester);
    });

    testWidgets('Mention switches to the message\'s channel and puts @login into its composer once', (tester) async {
      await showHome(tester);
      final l10n = AppLocalizations.of(tester.element(composer()));

      await tapInSheetOfB(tester, l10n.mentionUser);

      expect(find.byType(MessageModal), findsNothing);
      expect(shownChannel(tester), b);
      expect(tester.widget<TextField>(composer()).controller!.text, '@ronni');
      await finish(tester);
    });

    testWidgets('from the channel\'s own view the tab stays and the composer gets the mention', (tester) async {
      await showHome(tester);
      // To #b's tab first, then the sheet of one of its messages from its own chat.
      client.focusChannel('#b');
      await tester.pumpAndSettle();
      expect(shownChannel(tester), b);
      final l10n = AppLocalizations.of(tester.element(composer()));
      await tester.enterText(composer(), 'hi');
      await tester.pump();
      final view = tester.state(find.byType(ChannelView));

      await tapInMessageSheet(tester, l10n.mentionUser);

      // The same view, not one rebuilt after a tab change.
      expect(identical(tester.state(find.byType(ChannelView)), view), isTrue);
      expect(tester.widget<TextField>(composer()).controller!.text, 'hi @ronni');
      await finish(tester);
    });
  });
}

final _account = TwitchAccount(
  tokenData: TokenData(
    clientId: null,
    login: 'ronni',
    scopes: const [],
    userId: '1337',
    expiresAt: null,
    accessToken: 'token',
  ),
  userData: null,
  cookies: null,
);

class _TestSource extends ChatSource {
  @override
  String get name => '7TV';

  @override
  String? get description => null;
}
