import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../api/api_client.dart';
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

  /// Boxes earlier versions opened but never wrote anything to. Their files are deleted at startup.
  ///
  /// `ChatSettings`: opened since the Chatsen 2 code ColdChat is based on, but chat settings were always stored under
  /// the `chatSettings` key of the `Settings` box.
  static const List<String> unusedBoxNames = ['ChatSettings'];

  /// Deletes the files of [unusedBoxNames]. A failure is logged and otherwise ignored: the files are empty and harmless.
  static Future<void> deleteUnusedBoxes() async {
    for (final name in unusedBoxNames) {
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (e) {
        log('Could not delete the unused $name box: $e');
      }
    }
  }

  /// Opens every repository. Call after `Hive.initFlutter()` and registering the adapters. [api] downloads the emote
  /// button's image.
  static Future<Repositories> open(ApiClient api) async {
    // Not awaited: nothing depends on it, so it doesn't hold up the first frame.
    unawaited(deleteUnusedBoxes());
    // Hive's home folder is the documents folder too (see Hive.initFlutter).
    final accountsPath = Platform.isIOS
        ? '${(await getApplicationDocumentsDirectory()).path}/${AccountRepository.iosLoginsFolder}'
        : null;
    // Open the boxes concurrently instead of serially to shave startup time off the path before the first frame.
    final (accounts, settings, channels, whispers, triggers, customCommands, emoteBadgeCache, seenMentions) = await (
      AccountRepository.open(accountsPath: accountsPath),
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
      emoteButtonIcon: await EmoteButtonIcon.open(settings, api),
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
