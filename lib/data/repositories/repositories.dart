import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../emote_button_icon.dart';
import 'account_repository.dart';
import 'channel_repository.dart';
import 'custom_command_repository.dart';
import 'emote_badge_cache_repository.dart';
import 'seen_mentions_repository.dart';
import 'settings_repository.dart';
import 'trigger_repository.dart';
import 'whisper_repository.dart';

/// Every repository, opened once at startup. All of ColdChat's storage goes through these: nothing else opens a
/// Hive box.
class Repositories {
  final AccountRepository accounts;
  final SettingsRepository settings;
  final ChannelRepository channels;
  final WhisperRepository whispers;
  final TriggerRepository triggers;
  final CustomCommandRepository customCommands;
  final EmoteBadgeCacheRepository emoteBadgeCache;
  final SeenMentionsRepository seenMentions;
  final EmoteButtonIcon emoteButtonIcon;

  Repositories._({
    required this.accounts,
    required this.settings,
    required this.channels,
    required this.whispers,
    required this.triggers,
    required this.customCommands,
    required this.emoteBadgeCache,
    required this.seenMentions,
    required this.emoteButtonIcon,
  });

  /// Opens every repository. Call after `Hive.initFlutter()` and registering the adapters.
  static Future<Repositories> open() async {
    // Open the boxes concurrently instead of serially to shave startup time off the path before the first frame.
    final (accounts, settings, channels, whispers, triggers, customCommands, emoteBadgeCache, seenMentions) = await (
      AccountRepository.open(),
      SettingsRepository.open(),
      ChannelRepository.open(),
      WhisperRepository.open(),
      TriggerRepository.open(),
      CustomCommandRepository.open(),
      EmoteBadgeCacheRepository.open(),
      SeenMentionsRepository.open(),
    ).wait;
    return Repositories._(
      accounts: accounts,
      settings: settings,
      channels: channels,
      whispers: whispers,
      triggers: triggers,
      customCommands: customCommands,
      emoteBadgeCache: emoteBadgeCache,
      seenMentions: seenMentions,
      emoteButtonIcon: await EmoteButtonIcon.open(settings),
    );
  }

  /// The repositories widgets read with `context.read`. The chat client gets the others through its constructor.
  List<SingleChildWidget> get providers => [
    Provider<AccountRepository>.value(value: accounts),
    Provider<SettingsRepository>.value(value: settings),
    Provider<ChannelRepository>.value(value: channels),
    Provider<TriggerRepository>.value(value: triggers),
    Provider<CustomCommandRepository>.value(value: customCommands),
    Provider<SeenMentionsRepository>.value(value: seenMentions),
    Provider<EmoteButtonIcon>.value(value: emoteButtonIcon),
  ];
}
