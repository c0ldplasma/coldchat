import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:coldchat/components/glass.dart';
import 'package:coldchat/components/modal.dart';
import 'package:coldchat/components/pressable.dart';
import 'package:coldchat/components/tile.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/data/emote_button_icon.dart';
import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/home/emote_panel_cubit.dart';
import 'package:coldchat/data/live/live_channels_cubit.dart';
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
import 'package:coldchat/sheets/emote.dart';
import 'package:coldchat/sheets/message.dart';
import 'package:coldchat/sources/chat_source.dart';
import 'package:coldchat/sources/emote_source.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:coldchat/tmi/channel/can_send.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_chat.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:coldchat/tmi/connection/connection_event.dart';
import 'package:coldchat/tmi/connection/connection_state.dart' as tmi;
import 'package:coldchat/widgets/channel_switcher.dart';
import 'package:coldchat/widgets/channel_view.dart';
import 'package:coldchat/widgets/chat/emote_picker.dart';
import 'package:coldchat/widgets/chat_message.dart';
import 'package:coldchat/widgets/chat_view.dart';
import 'package:coldchat/widgets/emote_button_icon_view.dart';
import 'package:coldchat/widgets/emote_panel_host.dart';
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

  /// Logged in, as the composer needs: the transmitter is connected, but a new channel's JOIN isn't acknowledged yet,
  /// so the composer says it's connecting. Tests that change the transmitter go back to this.
  Future<void> loggedInConnecting() async {
    if (transmitter.state is tmi.ConnectionConnected) return;
    transmitter.add(ConnectionEstablished(tmi.ConnectionConnected(_account)));
    await transmitter.stream.firstWhere((state) => state is tmi.ConnectionConnected);
  }

  setUpAll(() async {
    transmitter = Connection(name: 'transmitter');
    await loggedInConnecting();
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
    // The keyboard the tests open is 336 high; with that saved, learning its height writes nothing.
    await settings.put(SettingsRepository.keyboardHeightKey, 336.0);
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
          BlocProvider<EmotePanelCubit>(create: (_) => EmotePanelCubit()),
          BlocProvider<LiveChannelsCubit>(
            create: (_) => LiveChannelsCubit(
              helix: () => null,
              logins: () => const [],
              channelChanges: const Stream.empty(),
              accountChanges: ChangeNotifier(),
              watchLifecycle: false,
            ),
          ),
        ],
        child: MaterialApp(
          theme: ColdChatTheme.build(ColdChatTheme.defaultAccent, Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ValueListenableBuilder<MediaQueryData>(
            valueListenable: mediaQuery,
            builder: (context, data, child) => MediaQuery(data: data, child: child!),
            // The emote panel is the home page's, in the keyboard's place.
            child: EmotePanelHost(
              channel: () => channel,
              child: Material(child: channelView),
            ),
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
  // The message field is the one that sends with the keyboard's return key; the emote panel has a search field too.
  Finder composer() => find.byWidgetPredicate((w) => w is TextField && w.textInputAction == TextInputAction.send);

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
    expect(tester.widget<ChatView>(find.byType(ChatView)).padding!.top, _statusBar);

    mediaQuery.value = mediaQuery.value.copyWith(viewPadding: const EdgeInsets.only(top: 59.0));
    await tester.pump();

    expect(tester.widget<ChatView>(find.byType(ChatView)).padding!.top, 59.0);
    await finish(tester);
  });

  testWidgets('the chat scrolls on below the floating composer, so the newest message can rise above it', (
    tester,
  ) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    final view = tester.getRect(find.byType(ChannelView));
    final chat = tester.getRect(find.byType(ChatView));
    final field = tester.getRect(composer());

    // The chat reaches the bottom, behind the composer, and keeps the composer's height free.
    expect(chat.bottom, view.bottom);
    expect(
      tester.widget<ChatView>(find.byType(ChatView)).padding!.bottom,
      greaterThanOrEqualTo(view.bottom - field.top),
    );
    await finish(tester);
  });

  /// Whether the send button in the message field is shown: it's always there, but without text it's faded out, closed
  /// and ignores taps.
  bool sendShown(WidgetTester tester) => !tester
      .widget<IgnorePointer>(
        find.ancestor(of: find.byIcon(Icons.arrow_upward_rounded), matching: find.byType(IgnorePointer)).first,
      )
      .ignoring;

  testWidgets('the send button shows up once there is text, and sends it', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    final channel = await showChannel(tester, mediaQuery);
    expect(sendShown(tester), isFalse);

    await tester.enterText(composer(), '   ');
    await tester.pumpAndSettle();
    expect(sendShown(tester), isFalse, reason: 'only spaces');

    await tester.enterText(composer(), 'hi');
    await tester.pumpAndSettle();
    expect(sendShown(tester), isTrue);

    await tester.runAsync(loggedInConnecting);
    channel.transmitterJoin.joined();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(composer()).controller!.text, isEmpty);
    expect(sendShown(tester), isFalse);

    // The transmitter is shared by every test here: leave it logged in but connecting again, as the next test expects.
    channel.transmitterJoin.parted();
    await tester.runAsync(loggedInConnecting);
    await finish(tester);
  });

  testWidgets('the emote button glides aside for the send button and back, instead of jumping', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    double emoteButtonX() => tester.getCenter(find.byType(EmoteButtonIconView)).dx;
    final start = emoteButtonX();

    Future<List<double>> positionsAfter(String text) async {
      await tester.enterText(composer(), text);
      final positions = <double>[];
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        positions.add(emoteButtonX());
      }
      return positions;
    }

    // Typing: it moves left over several frames, never back.
    final left = await positionsAfter('hi');
    expect(left.last, moreOrLessEquals(start - 34.0));
    expect(left.where((x) => x < start - 1.0 && x > left.last + 1.0), isNotEmpty, reason: 'it passes through between');
    for (var i = 1; i < left.length; i++) {
      expect(left[i], lessThanOrEqualTo(left[i - 1] + 0.01));
    }

    // Clearing the text: back right the same way.
    final right = await positionsAfter('');
    expect(right.last, moreOrLessEquals(start));
    expect(right.where((x) => x > left.last + 1.0 && x < start - 1.0), isNotEmpty, reason: 'it passes through between');
    for (var i = 1; i < right.length; i++) {
      expect(right[i], greaterThanOrEqualTo(right[i - 1] - 0.01));
    }
    await finish(tester);
  });

  testWidgets('the keyboard\'s send key puts the keyboard away while nothing is typed', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    FocusNode fieldFocus() => tester.widget<TextField>(composer()).focusNode!;

    await tester.tap(composer());
    await tester.enterText(composer(), '  ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(fieldFocus().hasFocus, isFalse);
    expect(tester.widget<TextField>(composer()).controller!.text, '  ');
    await finish(tester);
  });

  testWidgets('the emote panel and the keyboard take turns', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    final panel = BlocProvider.of<EmotePanelCubit>(tester.element(find.byType(ChannelView)));
    FocusNode fieldFocus() => tester.widget<TextField>(composer()).focusNode!;
    Pressable emoteButton() => tester.widget<Pressable>(
      find.ancestor(of: find.byType(EmoteButtonIconView), matching: find.byType(Pressable)).first,
    );

    await tester.tap(composer());
    await tester.pump();
    expect(fieldFocus().hasFocus, isTrue);

    // The emote button puts the keyboard away and opens the panel in its place.
    emoteButton().onTap!();
    await tester.pump(const Duration(milliseconds: 500));
    expect(panel.state, EmotePanel.open);
    expect(fieldFocus().hasFocus, isFalse);

    // Tapping into the field brings the keyboard back and closes the panel.
    await tester.tap(composer());
    await tester.pump(const Duration(milliseconds: 500));
    expect(fieldFocus().hasFocus, isTrue);
    expect(panel.state, EmotePanel.closed);

    // Long-pressing the button opens the panel to pick the button's emote.
    emoteButton().onLongPress!();
    await tester.pump(const Duration(milliseconds: 500));
    expect(panel.state, EmotePanel.pickingButtonIcon);
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
    expect(find.textContaining(l10n.replyingTo, findRichText: true), findsNothing);

    final replied = tester.widget<ChatMessage>(find.byType(ChatMessage).hitTestable().last).message;
    await tapInMessageSheet(tester, l10n.reply);

    expect(find.textContaining(l10n.replyingTo, findRichText: true), findsOneWidget);
    expect(channel.composerDraft.state, same(replied));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.textContaining(l10n.replyingTo, findRichText: true), findsNothing);
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
    await tester.runAsync(loggedInConnecting);
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

    // The transmitter is shared by every test here: leave it logged in but connecting again, as the next test expects.
    channel.transmitterJoin.parted();
    await tester.runAsync(loggedInConnecting);
    await finish(tester);
  });

  testWidgets('the composer says it is connecting until the channel can be written to', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    final channel = await showChannel(tester, mediaQuery);
    final l10n = AppLocalizations.of(tester.element(composer()));
    String? hint() => tester.widget<TextField>(composer()).decoration!.hintText;
    expect(hint(), l10n.channelConnecting('#ronni'));

    await tester.runAsync(loggedInConnecting);
    channel.transmitterJoin.joined();
    await tester.pump();
    expect(hint(), l10n.sendMessageIn('#ronni'));

    channel.transmitterJoin.parted();
    await tester.pump();
    expect(hint(), l10n.channelConnecting('#ronni'));

    await tester.runAsync(loggedInConnecting);
    await finish(tester);
  });

  Future<void> logOut(WidgetTester tester) => tester.runAsync(() async {
    transmitter.add(ConnectionDisconnect());
    await transmitter.stream.firstWhere((state) => state is tmi.ConnectionDisconnected);
  });

  testWidgets('logged out, the text field is a login button, and logging in brings it back', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await logOut(tester);
    final channel = await showChannel(tester, mediaQuery);
    final l10n = AppLocalizations.of(tester.element(find.byType(ChannelView)));

    expect(composer(), findsNothing);
    expect(find.text(l10n.logInToChat), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    // Uploads and the emote menu stay.
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byType(EmoteButtonIconView), findsOneWidget);

    await tester.runAsync(loggedInConnecting);
    await tester.pump();
    expect(find.text(l10n.logInToChat), findsNothing);
    expect(composer(), findsOneWidget);
    expect(channel.sendAvailability, SendAvailability.connecting);
    await finish(tester);
  });

  testWidgets('logged out, the upload sheet asks for a login and its choices do nothing', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await logOut(tester);
    await showChannel(tester, mediaQuery);
    final l10n = AppLocalizations.of(tester.element(find.byType(ChannelView)));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text(l10n.uploadNeedsLogin), findsOneWidget);

    // Tapping a greyed-out choice keeps the sheet open: nothing is picked or uploaded.
    await tester.tap(find.text(l10n.takePhoto));
    await tester.pumpAndSettle();
    expect(find.text(l10n.takePhoto), findsOneWidget);

    await tester.runAsync(loggedInConnecting);
    await finish(tester);
  });

  testWidgets('logged in, the upload sheet has no login row', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await showChannel(tester, mediaQuery);
    final l10n = AppLocalizations.of(tester.element(find.byType(ChannelView)));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text(l10n.takePhoto), findsOneWidget);
    expect(find.text(l10n.uploadNeedsLogin), findsNothing);
    await finish(tester);
  });

  testWidgets('logged out, tapping an emote in the emote menu shows it instead of typing it', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await logOut(tester);
    final channel = await showChannel(tester, mediaQuery);
    (channel.client as FakeClient).globals.emotes.change([
      Emote(id: 'pog', name: 'PogChamp', mipmap: ['https://example.com/pog'], source: _TestEmoteSource()),
    ]);

    // The buttons' own handlers: in this test's layout a tap on them lands on something else. Fixed pumps: the emote
    // images keep loading, so the frames never settle.
    tester
        .widget<Pressable>(find.ancestor(of: find.byType(EmoteButtonIconView), matching: find.byType(Pressable)).first)
        .onTap!();
    // The panel slides in from the next frame on.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // The emote's InkWell is inside its Tooltip.
    tester.widget<InkWell>(find.descendant(of: find.byTooltip('PogChamp'), matching: find.byType(InkWell))).onTap!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(EmoteModal), findsOneWidget);
    await tester.runAsync(loggedInConnecting);
    await tester.pump();
    // The composer's field comes first; the emote menu's search field is below it.
    expect(tester.widget<TextField>(composer().first).controller!.text, isEmpty);
    await finish(tester);
  });

  testWidgets('logged out, the message sheet has no Reply or Mention', (tester) async {
    final mediaQuery = statusBarOnly();
    addTearDown(mediaQuery.dispose);
    await logOut(tester);
    final channel = await showChannel(tester, mediaQuery);
    final context = tester.element(find.byType(ChannelView));
    final l10n = AppLocalizations.of(context);

    unawaited(
      Modal.show(
        context: context,
        child: MessageModal(message: _message(1, channel)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.copyText), findsOneWidget);
    expect(find.text(l10n.reply), findsNothing);
    expect(find.text(l10n.mentionUser), findsNothing);

    await tester.runAsync(loggedInConnecting);
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
            BlocProvider<LiveChannelsCubit>(
              create: (_) => LiveChannelsCubit(
                helix: () => null,
                logins: () => const [],
                channelChanges: const Stream.empty(),
                accountChanges: ChangeNotifier(),
                watchLifecycle: false,
              ),
            ),
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
      expect(find.byType(ChannelSwitcher), findsNothing);
      expect(find.byType(ChannelView), findsNothing);

      // In real time: a write to the settings box started in the test's fake time never finishes, and Hive would wait
      // for it when closing.
      await tester.runAsync(() async {
        await tester.tap(find.text(l10n.continueWithoutLogin));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.byType(LoggedOutStart), findsNothing);
      expect(find.byType(ChannelSwitcher), findsOneWidget);
      expect(SettingsRepository(Hive.box<dynamic>('Settings')).startScreenDone, isTrue);
    });

    Channel shownChannel(WidgetTester tester) => tester.widget<ChannelView>(find.byType(ChannelView)).channel;

    Finder switcherTab(String label) => find.descendant(of: find.byType(ChannelSwitcher), matching: find.text(label));

    testWidgets('the search button puts the cursor in the home tab\'s search, also with the page scrolled down', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1206.0, 2622.0);
      addTearDown(tester.view.reset);
      await showHome(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(ChannelSwitcher)));

      // To the home tab, scrolled down as far as it goes.
      await tester.tap(find.descendant(of: find.byType(ChannelSwitcher), matching: find.byIcon(Icons.home_rounded)));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0.0, -2000.0));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byType(ChannelSwitcher), matching: find.byIcon(Icons.search_rounded)));
      await tester.pumpAndSettle();

      final search = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == l10n.searchForChannels,
      );
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
      // On screen, right under the avatar row.
      expect(tester.getRect(search).top, greaterThan(0.0));
      expect(tester.getRect(search).bottom, lessThan(200.0));
    });

    testWidgets('joining another channel adds its tab', (tester) async {
      await showHome(tester);
      final c = Channel(client: client, name: '#c');
      addTearDown(c.close);

      // A new tab count makes a new TabController; with a single-ticker State that threw in debug builds.
      (client.channels as FakeChannels).show([a, b, c]);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(switcherTab('c'), findsOneWidget);
    });

    testWidgets('the composer stays put between the keyboard and the emote panel, above the covered switcher', (
      tester,
    ) async {
      // An iPhone 18 Pro with its keyboard: 402 x 874 points, the home indicator's 34 and a 336 point keyboard.
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1206.0, 2622.0);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34.0 * 3.0);
      tester.view.padding = const FakeViewPadding(bottom: 34.0 * 3.0);
      addTearDown(tester.view.reset);
      Future<void> keyboard(double height) async {
        tester.view.viewInsets = FakeViewPadding(bottom: height * 3.0);
        tester.view.padding = FakeViewPadding(bottom: height > 0.0 ? 0.0 : 34.0 * 3.0);
        await tester.pump();
      }

      Future<void> frames() async {
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await showHome(tester);
      final panel = BlocProvider.of<EmotePanelCubit>(tester.element(find.byType(ChannelView)));
      double composerBottom() => tester.getRect(composer()).bottom;
      final switcherTop = tester.getRect(find.byType(ChannelSwitcher)).top;
      expect(composerBottom(), lessThan(switcherTop));

      // The keyboard opens over the switcher, which stays where it is; the composer rides on the keyboard.
      await tester.tap(composer());
      for (final inset in [100.0, 200.0, 336.0]) {
        await keyboard(inset);
      }
      final onKeyboard = composerBottom();
      expect(onKeyboard, lessThan(874.0 - 336.0));
      expect(tester.getRect(find.byType(ChannelSwitcher)).top, switcherTop);

      // The emote button: the panel takes the keyboard's height behind it, and the keyboard slides away over it.
      tester
          .widget<Pressable>(
            find.ancestor(of: find.byType(EmoteButtonIconView), matching: find.byType(Pressable)).first,
          )
          .onTap!();
      await tester.pump();
      for (final inset in [336.0, 200.0, 100.0, 0.0]) {
        await keyboard(inset);
        expect(composerBottom(), moreOrLessEquals(onKeyboard), reason: 'keyboard at $inset');
      }
      await frames();
      expect(panel.state, EmotePanel.open);
      expect(composerBottom(), moreOrLessEquals(onKeyboard));

      // Tapping into the field: the keyboard rises over the panel, which goes once it is covered. Its emotes fade on
      // the way, since iOS's keyboard is translucent.
      double emoteOpacity() => tester
          .widget<Opacity>(find.ancestor(of: find.byType(EmotePicker), matching: find.byType(Opacity)).first)
          .opacity;
      expect(emoteOpacity(), 1.0);
      await tester.tap(composer());
      await tester.pump();
      var lastOpacity = 1.0;
      for (final inset in [100.0, 200.0, 336.0]) {
        await keyboard(inset);
        expect(composerBottom(), moreOrLessEquals(onKeyboard), reason: 'keyboard at $inset');
        if (find.byType(EmotePicker).evaluate().isNotEmpty) {
          expect(emoteOpacity(), lessThan(lastOpacity), reason: 'keyboard at $inset');
          lastOpacity = emoteOpacity();
        }
      }
      await frames();
      expect(panel.state, EmotePanel.closed);
      expect(find.byType(EmotePicker), findsNothing);
      expect(composerBottom(), moreOrLessEquals(onKeyboard));

      // Closing the keyboard: the composer comes down onto the switcher and stops there, without overshooting.
      var lowest = 0.0;
      for (final inset in [200.0, 100.0, 50.0, 0.0]) {
        await keyboard(inset);
        lowest = math.max(lowest, composerBottom());
      }
      await frames();
      expect(lowest, lessThan(switcherTop));
      expect(composerBottom(), lessThan(switcherTop));
    });

    testWidgets('the search button in the emote panel\'s section bar scrolls back up to the search field', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1206.0, 2622.0);
      addTearDown(tester.view.reset);
      await showHome(tester);
      BlocProvider.of<EmotePanelCubit>(tester.element(find.byType(ChannelView))).toggle();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final l10n = AppLocalizations.of(tester.element(find.byType(EmotePicker)));
      final search = find.descendant(of: find.byType(EmotePicker), matching: find.byType(TextField));
      final grid = tester.widget<CustomScrollView>(
        find.descendant(of: find.byType(EmotePicker), matching: find.byType(CustomScrollView)),
      );
      grid.controller!.jumpTo(200.0);
      await tester.pump();

      await tester.tap(find.descendant(of: find.byType(EmotePicker), matching: find.byTooltip(l10n.search)));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Back at the top, with the search field in view; the keyboard only comes with a tap into it.
      expect(grid.controller!.offset, 0.0);
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isFalse);
    });

    testWidgets('searching the emote panel keeps its search field and the composer above the keyboard', (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1206.0, 2622.0);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34.0 * 3.0);
      tester.view.padding = const FakeViewPadding(bottom: 34.0 * 3.0);
      addTearDown(tester.view.reset);
      await showHome(tester);

      BlocProvider.of<EmotePanelCubit>(tester.element(find.byType(ChannelView))).toggle();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final search = find.descendant(of: find.byType(EmotePicker), matching: find.byType(TextField));
      final pickerTop = tester.getRect(find.byType(EmotePicker)).top;
      await tester.tap(search);
      // The keyboard comes up for the search field.
      for (final inset in [100.0, 200.0, 336.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset * 3.0);
        tester.view.padding = FakeViewPadding.zero;
        await tester.pump();
      }

      const keyboardTop = 874.0 - 336.0;
      // The panel keeps its search field, and the field the keyboard, while the keyboard comes up: a rebuilt field
      // would close the keyboard it had just asked for.
      expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(tester.getRect(search).bottom, lessThan(keyboardTop));
      // The results end at the keyboard, so the last ones can scroll up into view.
      expect(tester.getRect(find.byType(EmotePicker)).bottom, moreOrLessEquals(keyboardTop));
      expect(tester.getRect(composer()).bottom, lessThan(tester.getRect(find.byType(EmotePicker)).top));

      // The keyboard going away shrinks the panel back to its height before the search.
      tester.view.viewInsets = FakeViewPadding.zero;
      tester.view.padding = const FakeViewPadding(bottom: 34.0 * 3.0);
      await tester.pump();
      expect(tester.getRect(find.byType(EmotePicker)).top, moreOrLessEquals(pickerTop));
    });

    testWidgets('the emote panel shrinks back with the keyboard when its search loses the keyboard', (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1206.0, 2622.0);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34.0 * 3.0);
      tester.view.padding = const FakeViewPadding(bottom: 34.0 * 3.0);
      addTearDown(tester.view.reset);
      await showHome(tester);

      BlocProvider.of<EmotePanelCubit>(tester.element(find.byType(ChannelView))).toggle();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final search = find.descendant(of: find.byType(EmotePicker), matching: find.byType(TextField));
      final pickerTop = tester.getRect(find.byType(EmotePicker)).top;
      // The section bar's glass capsule, hidden while searching.
      final sectionBar = find.descendant(of: find.byType(EmotePicker), matching: find.byType(Glass));
      final sectionBarBottom = tester.getRect(sectionBar).bottom;
      await tester.tap(search);
      for (final inset in [100.0, 200.0, 336.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset * 3.0);
        tester.view.padding = FakeViewPadding.zero;
        await tester.pump();
      }
      final searchTop = tester.getRect(find.byType(EmotePicker)).top;
      expect(searchTop, lessThan(pickerTop));

      // The search field loses the keyboard (its done key), which then slides down: the panel goes down with it,
      // never below its height before the search, instead of jumping there at once.
      tester.widget<TextField>(search).focusNode!.unfocus();
      await tester.pump();
      expect(tester.getRect(find.byType(EmotePicker)).top, moreOrLessEquals(searchTop));
      var previous = searchTop;
      // The section bar is back at its place at the panel's bottom, behind the keyboard, and stays there: the keyboard
      // reveals it as it slides away.
      expect(tester.getRect(sectionBar).bottom, moreOrLessEquals(sectionBarBottom));
      for (final inset in [300.0, 250.0, 200.0, 100.0, 20.0, 0.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset * 3.0);
        if (inset == 0.0) tester.view.padding = const FakeViewPadding(bottom: 34.0 * 3.0);
        await tester.pump();
        final top = tester.getRect(find.byType(EmotePicker)).top;
        expect(top, greaterThanOrEqualTo(previous - 0.01), reason: 'keyboard at $inset');
        expect(top, lessThanOrEqualTo(pickerTop + 0.01), reason: 'keyboard at $inset');
        previous = top;
        expect(tester.getRect(sectionBar).bottom, moreOrLessEquals(sectionBarBottom), reason: 'keyboard at $inset');
      }
      // It moved in steps with the keyboard, not all at once at the end.
      expect(previous, moreOrLessEquals(pickerTop));
    });

    testWidgets('behind the keyboard alone is the chat\'s color, not the emote panel\'s', (tester) async {
      await showHome(tester);
      final theme = Theme.of(tester.element(find.byType(ChannelView)));
      Iterable<Color> behindKeyboard() => tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(EmotePanelHost),
              matching: find.byWidgetPredicate((w) => w is ColoredBox && w.key == null),
            ),
          )
          .map((box) => box.color);

      tester.view.viewInsets = FakeViewPadding(bottom: 336.0 * tester.view.devicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(behindKeyboard(), contains(theme.colorScheme.surface));
      expect(behindKeyboard(), isNot(contains(ChatColors.of(tester.element(find.byType(ChannelView))).sheet)));
    });

    testWidgets('the emote panel\'s section bar stays clear of the home indicator, with the emotes below it', (
      tester,
    ) async {
      // An iPhone 18 Pro: 402 x 874 points, with the home indicator's 34 below.
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(1206.0, 2622.0);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34.0 * 3.0);
      tester.view.padding = const FakeViewPadding(bottom: 34.0 * 3.0);
      addTearDown(tester.view.reset);
      await showHome(tester);

      BlocProvider.of<EmotePanelCubit>(tester.element(find.byType(ChannelView))).toggle();
      // The panel slides open (no pumpAndSettle: its spinners keep the frames from settling).
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The emotes run to the screen's edge, scrolling on below the section bar. That floats where the channel
      // switcher's capsule (covered by the panel now) is, above the home indicator.
      expect(tester.getRect(find.byType(EmotePicker)).bottom, 874.0);
      final sectionBar = find.descendant(of: find.byType(EmotePicker), matching: find.byType(Glass));
      final switcherCapsule = find.descendant(of: find.byType(ChannelSwitcher), matching: find.byType(Glass)).first;
      expect(tester.getRect(sectionBar).bottom, lessThanOrEqualTo(874.0 - 34.0));
      expect(tester.getRect(sectionBar).bottom, moreOrLessEquals(tester.getRect(switcherCapsule).bottom));
    });

    testWidgets('switching to another tab closes the emote panel', (tester) async {
      await showHome(tester);
      final panel = BlocProvider.of<EmotePanelCubit>(tester.element(find.byType(ChannelView)));
      panel.toggle();
      await tester.pump(const Duration(milliseconds: 500));

      tester.widget<TabBarView>(find.byType(TabBarView)).controller!.animateTo(2);
      await tester.pumpAndSettle();

      expect(shownChannel(tester), same(b));
      expect(panel.state, EmotePanel.closed);
    });

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
      expect(find.textContaining(l10n.replyingTo, findRichText: true), findsOneWidget);
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

class _TestEmoteSource extends ChatSource with EmoteSource {
  @override
  String get name => '7TV';

  @override
  String? get description => null;

  @override
  String? emoteUrl(String id) => null;
}
