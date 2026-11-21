import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

import 'data/notifications_cubit.dart';
import 'data/repositories/seen_mentions_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'l10n/app_localizations.dart';
import 'pages/home.dart';
import 'theme/coldchat_theme.dart';
import 'tmi/channel/channel_message.dart';
import 'tmi/channel/messages/channel_message_chat.dart';
import 'tmi/client/client.dart';
import 'tmi/client/client_listener.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver implements ClientListener {
  /// Kept for [dispose], where looking up providers through the deactivated context throws.
  late final Client _client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _client = context.read<Client>()..listeners.add(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _client.listeners.remove(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check liveness on every foreground; onAppResumed no-ops if the socket is
    // still alive, so a quick app-switch costs nothing. Don't gate on measured
    // background duration — iOS lifecycle events are unreliable for that.
    if (state == AppLifecycleState.resumed) {
      unawaited(_client.onAppResumed());
    }
  }

  @override
  Future<ChannelMessage> onMessageReceived(ChannelMessage message) async {
    if (message is ChannelMessageChat) {
      if (message.mentionned) {
        // The message stays visually highlighted regardless; we only avoid
        // re-adding a notification for a mention we already surfaced in a
        // previous session (e.g. when it comes back via history on launch).
        final seenMentions = context.read<SeenMentionsRepository>();
        if (!seenMentions.contains(message.id)) {
          context.read<NotificationsCubit>().add(message);
          seenMentions.markSeen(message.id);
        }
      }
    }
    return message;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<SettingsRepository>().appChanges,
    builder: (context, _) {
      final settings = context.read<SettingsRepository>();
      final applicationAppearance = settings.applicationAppearance;
      final accent = settings.accent;
      final matchingCustomLocale = AppLocalizations.supportedLocales.firstWhereOrNull(
        (element) => element.toLanguageTag() == settings.locale,
      );
      return MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          LocaleNamesLocalizationsDelegate(),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: matchingCustomLocale,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                statusBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.light
                    ? Brightness.dark
                    : Brightness.light,
                statusBarBrightness: Theme.of(context).brightness == Brightness.light
                    ? Brightness.light
                    : Brightness.dark,
                statusBarIconBrightness: Theme.of(context).brightness == Brightness.light
                    ? Brightness.dark
                    : Brightness.light,
              ),
              child: Stack(
                children: [
                  const HomePage(),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    height: MediaQuery.viewPaddingOf(context).top,
                  ),
                ],
              ),
            );
          },
        ),
        theme: ColdChatTheme.build(accent, Brightness.light, highContrast: applicationAppearance.highContrast),
        darkTheme: ColdChatTheme.build(
          accent,
          Brightness.dark,
          highContrast: applicationAppearance.highContrast,
          oledBlack: applicationAppearance.oledBlack,
        ),
        themeMode: applicationAppearance.themeMode == 'dark'
            ? ThemeMode.dark
            : applicationAppearance.themeMode == 'light'
            ? ThemeMode.light
            : ThemeMode.system,
        scrollBehavior: CustomScrollBehavior(),
      );
    },
  );
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
