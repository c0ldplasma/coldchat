import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'data/custom_command.dart';
import 'data/emote_button_icon.dart';
import 'data/filesharing/upload_queue_cubit.dart';
import 'data/filesharing/uploaded_media.dart';
import 'data/message_trigger.dart';
import 'data/notifications_cubit.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/channel_repository.dart';
import 'data/repositories/custom_command_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/trigger_repository.dart';
import 'data/repositories/whisper_repository.dart';
import 'data/settings/application_appearance.dart';
import 'data/settings/blocked_message.dart';
import 'data/settings/blocked_user.dart';
import 'data/settings/chat_settings.dart';
import 'data/settings/mention_message.dart';
import 'data/settings/mention_user.dart';
import 'data/settings/message_appearance.dart';
import 'data/twitch/token_data.dart';
import 'data/twitch/user_data.dart';
import 'data/twitch_account.dart';
import 'data/user_trigger.dart';
import 'data/webview/cookie_data.dart';
import 'tmi/client/client.dart';
import 'tools/coldchat_binding.dart';

Future<void> main() async {
  ColdChatBinding.ensureInitialized();

  await WakelockPlus.enable();

  // Fonts aren't pub packages, so their license has to be added to the license page by hand.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Google Sans Flex'], await rootBundle.loadString('fonts/OFL.txt'));
  });

  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  await Hive.initFlutter();

  Hive.registerAdapter(TwitchAccountAdapter());
  Hive.registerAdapter(TokenDataAdapter());
  Hive.registerAdapter(UserDataAdapter());
  Hive.registerAdapter(CookieDataAdapter());
  Hive.registerAdapter(UploadedMediaAdapter());
  Hive.registerAdapter(MessageAppearanceAdapter());
  Hive.registerAdapter(ApplicationAppearanceAdapter());
  Hive.registerAdapter(BlockedMessageAdapter());
  Hive.registerAdapter(BlockedUserAdapter());
  Hive.registerAdapter(MentionMessageAdapter());
  Hive.registerAdapter(MentionUserAdapter());
  Hive.registerAdapter(CustomCommandAdapter());
  Hive.registerAdapter(MessageTriggerAdapter());
  Hive.registerAdapter(UserTriggerAdapter());
  Hive.registerAdapter(ChatSettingsAdapter());

  // Open all Hive boxes concurrently instead of serially to shave startup
  // time off the path before the first frame.
  final boxes = await Future.wait([
    Hive.openBox<dynamic>('EmoteBadgeCache'),
    Hive.openBox<dynamic>('SeenMentions'),
    Hive.openBox<dynamic>('ChatSettings'),
  ]);
  final emoteBadgeCacheBox = boxes[0];
  final accounts = await AccountRepository.open();
  final settings = await SettingsRepository.open();
  final emoteButtonIcon = await EmoteButtonIcon.open(settings);
  final channels = await ChannelRepository.open();
  final whispers = await WhisperRepository.open();
  final triggers = await TriggerRepository.open();
  final customCommands = await CustomCommandRepository.open();

  // await settingsBox.clear();

  final activeTwitchAccount = accounts.active;

  runApp(
    MultiProvider(
      providers: [
        Provider<AccountRepository>.value(value: accounts),
        Provider<SettingsRepository>.value(value: settings),
        Provider<EmoteButtonIcon>.value(value: emoteButtonIcon),
        Provider<ChannelRepository>.value(value: channels),
        Provider<TriggerRepository>.value(value: triggers),
        Provider<CustomCommandRepository>.value(value: customCommands),
        Provider<Client>(
          create: (context) => Client(
            twitchAccount: activeTwitchAccount,
            accounts: accounts,
            triggers: triggers,
            channelRepository: channels,
            cacheBox: emoteBadgeCacheBox,
            whisperRepository: whispers,
          ),
        ),
        Provider<NotificationsCubit>(create: (context) => NotificationsCubit()),
        // Above the channel views on purpose: an upload must survive switching
        // tabs and must never be awaited by the composer.
        Provider<UploadQueueCubit>(create: (context) => UploadQueueCubit()),
      ],
      child: const App(),
    ),
  );
}
