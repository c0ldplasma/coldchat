import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../theme/coldchat_theme.dart';
import '../settings/application_appearance.dart';
import '../settings/chat_settings.dart';
import '../settings/message_appearance.dart';
import 'box_changes.dart';

/// The app's settings: the `Settings` box, apart from the last opened channel, which [ChannelRepository] keeps there.
class SettingsRepository {
  static const String boxName = 'Settings';

  static const String messageAppearanceKey = 'messageAppearance';
  static const String applicationAppearanceKey = 'applicationAppearance';
  static const String chatSettingsKey = 'chatSettings';

  /// A language tag from [AppLocalizations.supportedLocales], or none for the system's language.
  static const String localeKey = 'locale';

  /// The [AccentColor.id] of the accent color.
  static const String accentKey = 'accentColor';

  /// The custom accent's hue and chroma, kept next to [accentKey] while another accent is picked.
  static const String customHueKey = 'accentHue';
  static const String customChromaKey = 'accentChroma';

  /// The ARGB value of the primary color picked in the old color list, before accent colors.
  static const String legacyColorKey = 'themeColor';

  /// A map with the emote menu button's emote `name` and either an image `file` name or an `emoji`.
  static const String emoteButtonIconKey = 'emoteButtonIcon';
  static const String emoteButtonGrayscaleKey = 'emoteButtonGrayscale';

  static const String chatHistoryKey = 'recentMessagesChatHistory';
  static const String whisperHistoryHintDismissedKey = 'whisperHistoryHintDismissed';

  /// The on-screen keyboard's height when last seen open, which the emote panel takes in its place.
  static const String keyboardHeightKey = 'keyboardHeight';

  /// The emote picker's sections whose emotes the picker and the suggestions leave out: a map from the section's key
  /// (`emoteSectionKey`: a channel's user id, or `section:<title>`) to its title at the time it was hidden, for the
  /// list in Settings. Named from when only channels' sections could be hidden.
  static const String hiddenEmoteSectionsKey = 'hiddenEmoteChannels';

  /// Set once the full-screen start screen was left, by logging in or "Continue without logging in".
  static const String startScreenDoneKey = 'startScreenDone';

  final Box<dynamic> _box;

  /// Takes the open `Settings` box; [open] opens it.
  SettingsRepository(this._box);

  static Future<SettingsRepository> open() async {
    final repository = SettingsRepository(await Hive.openBox<dynamic>(boxName));
    await repository._init();
    return repository;
  }

  /// Stores the appearance objects that the settings screens edit in place, and moves an accent picked in the old
  /// color list over.
  Future<void> _init() async {
    if (!_box.containsKey(messageAppearanceKey)) await _box.put(messageAppearanceKey, MessageAppearance());
    if (!_box.containsKey(applicationAppearanceKey)) {
      await _box.put(applicationAppearanceKey, ApplicationAppearance());
    }
    await _migrateAccent();
    if (!_box.containsKey(chatSettingsKey)) await _box.put(chatSettingsKey, ChatSettings());
  }

  /// The stored value under [key], or a new [create]d one that is stored, so that the object can be saved later.
  T _stored<T>(String key, T Function() create) {
    final value = _box.get(key);
    if (value is T) return value;
    final created = create();
    unawaited(_box.put(key, created));
    return created;
  }

  /// Every change, to any setting.
  late final Listenable changes = BoxChanges(_box);

  MessageAppearance get messageAppearance => _stored(messageAppearanceKey, MessageAppearance.new);

  /// Saves [value], the object [messageAppearance] returned, after changing it.
  Future<void> saveMessageAppearance(MessageAppearance value) => _box.put(messageAppearanceKey, value);

  late final Listenable messageAppearanceChanges = BoxChanges(_box, keys: const [messageAppearanceKey]);

  ApplicationAppearance get applicationAppearance => _stored(applicationAppearanceKey, ApplicationAppearance.new);

  /// Saves [value], the object [applicationAppearance] returned, after changing it.
  Future<void> saveApplicationAppearance(ApplicationAppearance value) => _box.put(applicationAppearanceKey, value);

  ChatSettings get chatSettings => _stored(chatSettingsKey, ChatSettings.new);

  /// Saves [value], the object [chatSettings] returned, after changing it.
  Future<void> saveChatSettings(ChatSettings value) => _box.put(chatSettingsKey, value);

  late final Listenable chatSettingsChanges = BoxChanges(_box, keys: const [chatSettingsKey]);

  /// The language tag picked in the app, or null for the system's language.
  String? get locale {
    final value = _box.get(localeKey);
    return value is String ? value : null;
  }

  Future<void> setLocale(String? languageTag) => _box.put(localeKey, languageTag);

  /// What the whole app's theme and language depend on. Other settings, e.g. the last channel that is written on
  /// every tab swipe, must not rebuild the whole app.
  late final Listenable appChanges = BoxChanges(
    _box,
    keys: const [applicationAppearanceKey, localeKey, accentKey, customHueKey, customChromaKey],
  );

  /// The accent color, or the default.
  AccentColor get accent {
    final id = _box.get(accentKey);
    if (id == ColdChatTheme.customId) {
      final hue = customHue;
      final chroma = customChroma;
      if (hue != null && chroma != null) return ColdChatTheme.custom(hue, chroma);
    }
    return ColdChatTheme.accentById(id is String ? id : null);
  }

  /// The last custom color's hue, also while another accent is picked.
  double? get customHue {
    final value = _box.get(customHueKey);
    return value is double ? value : null;
  }

  /// The last custom color's chroma, also while another accent is picked.
  double? get customChroma {
    final value = _box.get(customChromaKey);
    return value is double ? value : null;
  }

  /// Picks one of [ColdChatTheme.accents].
  Future<void> setAccent(AccentColor accent) => _box.put(accentKey, accent.id);

  /// Picks a custom color, as hue (0–360) and chroma (0–[ColdChatTheme.maxChroma]).
  Future<void> setCustomAccent(double hue, double chroma) => _box.putAll({
    accentKey: ColdChatTheme.customId,
    customHueKey: hue,
    customChromaKey: chroma,
  });

  /// Moves a color picked in the old list over to the closest accent, so an update changes as little as possible.
  /// New installs get no entry and so the default.
  Future<void> _migrateAccent() async {
    if (_box.containsKey(accentKey)) return;
    final legacy = _box.get(legacyColorKey);
    if (legacy is! int) return;
    await _box.put(accentKey, ColdChatTheme.closestAccent(Color(legacy)).id);
  }

  /// The emote menu button's stored icon (see [emoteButtonIconKey]), or null for Kappa.
  Map<dynamic, dynamic>? get emoteButtonIcon {
    final value = _box.get(emoteButtonIconKey);
    return value is Map ? value : null;
  }

  Future<void> setEmoteButtonIcon(Map<String, String?>? icon) =>
      icon == null ? _box.delete(emoteButtonIconKey) : _box.put(emoteButtonIconKey, icon);

  bool get emoteButtonGrayscale => _box.get(emoteButtonGrayscaleKey) == true;

  Future<void> setEmoteButtonGrayscale(bool value) => _box.put(emoteButtonGrayscaleKey, value);

  late final Listenable emoteButtonChanges = BoxChanges(
    _box,
    keys: const [emoteButtonIconKey, emoteButtonGrayscaleKey],
  );

  /// Settings → Chat history: whether chat history from before joining is fetched from recent-messages.robotty.de
  /// (see `RecentMessages`). On unless turned off, also for installs that never touched the switch.
  bool get chatHistory {
    final value = _box.get(chatHistoryKey);
    return value is bool ? value : true;
  }

  Future<void> setChatHistory(bool value) => _box.put(chatHistoryKey, value);

  bool get whisperHistoryHintDismissed => _box.get(whisperHistoryHintDismissedKey) == true;

  Future<void> dismissWhisperHistoryHint() => _box.put(whisperHistoryHintDismissedKey, true);

  /// The keyboard's height when last seen open, or null before it ever was.
  double? get keyboardHeight {
    final value = _box.get(keyboardHeightKey);
    return value is num && value > 0 ? value.toDouble() : null;
  }

  Future<void> setKeyboardHeight(double height) => _box.put(keyboardHeightKey, height);

  /// The picker's hidden sections, by key, with their titles; see [hiddenEmoteSectionsKey].
  Map<String, String> get hiddenEmoteSections {
    final value = _box.get(hiddenEmoteSectionsKey);
    if (value is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in value.entries)
        if (key is String && value is String) key: value,
    };
  }

  /// Hides the emotes of the section [key], titled [title], from the picker and the suggestions.
  Future<void> hideEmoteSection(String key, String title) =>
      _box.put(hiddenEmoteSectionsKey, {...hiddenEmoteSections, key: title});

  /// Shows the emotes of the section [key] again.
  Future<void> showEmoteSection(String key) => _box.put(hiddenEmoteSectionsKey, {...hiddenEmoteSections}..remove(key));

  late final Listenable hiddenEmoteSectionsChanges = BoxChanges(_box, keys: const [hiddenEmoteSectionsKey]);

  /// Whether the full-screen start screen of a fresh install was left; it never shows again then.
  bool get startScreenDone => _box.get(startScreenDoneKey) == true;

  Future<void> finishStartScreen() => _box.put(startScreenDoneKey, true);

  late final Listenable startScreenChanges = BoxChanges(_box, keys: const [startScreenDoneKey]);
}
