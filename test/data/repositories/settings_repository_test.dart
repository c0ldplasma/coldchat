import 'dart:io';
import 'dart:ui' show Color;

import 'package:coldchat/api/emojis/emoji_data.dart';
import 'package:coldchat/api/seventv/seventv.dart';
import 'package:coldchat/data/emote.dart';
import 'package:coldchat/data/emote_button_icon.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/data/settings/application_appearance.dart';
import 'package:coldchat/data/settings/chat_settings.dart';
import 'package:coldchat/data/settings/message_appearance.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/sources/emoji_source.dart';
import 'package:coldchat/sources/seventv_source.dart';
import 'package:coldchat/theme/coldchat_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;

import '../../api/fake_api.dart';

void main() {
  late Directory tempDir;

  setUpAll(Hive.registerAdapters);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_settings_repository_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  /// The Settings box as an earlier version left it, before the repository opens it.
  Future<Box<dynamic>> stored(Map<String, Object?> entries) async {
    final box = await Hive.openBox<dynamic>('Settings');
    await box.putAll(entries);
    return box;
  }

  test('uses the existing box and keys', () {
    expect(SettingsRepository.boxName, 'Settings');
    expect(SettingsRepository.messageAppearanceKey, 'messageAppearance');
    expect(SettingsRepository.applicationAppearanceKey, 'applicationAppearance');
    expect(SettingsRepository.chatSettingsKey, 'chatSettings');
    expect(SettingsRepository.localeKey, 'locale');
    expect(SettingsRepository.accentKey, 'accentColor');
    expect(SettingsRepository.customHueKey, 'accentHue');
    expect(SettingsRepository.customChromaKey, 'accentChroma');
    expect(SettingsRepository.legacyColorKey, 'themeColor');
    expect(SettingsRepository.emoteButtonIconKey, 'emoteButtonIcon');
    expect(SettingsRepository.emoteButtonGrayscaleKey, 'emoteButtonGrayscale');
    expect(SettingsRepository.chatHistoryKey, 'recentMessagesChatHistory');
    expect(SettingsRepository.whisperHistoryHintDismissedKey, 'whisperHistoryHintDismissed');
    expect(SettingsRepository.keyboardHeightKey, 'keyboardHeight');
  });

  test('a fresh install stores default appearance and chat settings, and gets no accent entry', () async {
    final settings = await SettingsRepository.open();
    final box = Hive.box<dynamic>('Settings');

    expect(box.get('messageAppearance'), isA<MessageAppearance>());
    expect(box.get('applicationAppearance'), isA<ApplicationAppearance>());
    expect(box.get('chatSettings'), isA<ChatSettings>());
    expect(box.containsKey('accentColor'), isFalse);

    expect(settings.messageAppearance, same(box.get('messageAppearance')));
    expect(settings.accent, ColdChatTheme.defaultAccent);
    expect(settings.locale, isNull);
    expect(settings.chatHistory, isTrue);
    expect(settings.whisperHistoryHintDismissed, isFalse);
    expect(settings.emoteButtonIcon, isNull);
    expect(settings.emoteButtonGrayscale, isFalse);
    expect(settings.keyboardHeight, isNull);
  });

  test('remembers the keyboard\'s height and ignores nonsense', () async {
    final settings = await SettingsRepository.open();

    await settings.setKeyboardHeight(336.0);
    expect(settings.keyboardHeight, 336.0);

    await Hive.box<dynamic>('Settings').put(SettingsRepository.keyboardHeightKey, 'tall');
    expect(settings.keyboardHeight, isNull);
    await Hive.box<dynamic>('Settings').put(SettingsRepository.keyboardHeightKey, 0);
    expect(settings.keyboardHeight, isNull);
  });

  test('hides emote sections across launches and shows them again', () async {
    var settings = await SettingsRepository.open();
    expect(settings.hiddenEmoteSections, isEmpty);
    var notified = 0;
    settings.emoteSectionChanges.addListener(() => notified++);

    await settings.hideEmoteSection('1', 'Anime_Marathon_1');
    await settings.hideEmoteSection('section:7TV', '7TV');
    await pumpEventQueue();
    expect(notified, 2);

    await Hive.close();
    Hive.init(tempDir.path);
    settings = await SettingsRepository.open();
    expect(settings.hiddenEmoteSections, {'1': 'Anime_Marathon_1', 'section:7TV': '7TV'});

    await settings.showEmoteSection('1');
    expect(settings.hiddenEmoteSections, {'section:7TV': '7TV'});

    // Something else stored under the key reads as nothing hidden.
    await Hive.box<dynamic>('Settings').put(SettingsRepository.hiddenEmoteSectionsKey, 'nonsense');
    expect(settings.hiddenEmoteSections, isEmpty);
  });

  test('keeps the arranged order of the emote sections, and resets it', () async {
    var settings = await SettingsRepository.open();
    expect(settings.emoteSectionOrder, isEmpty);
    var notified = 0;
    settings.emoteSectionChanges.addListener(() => notified++);

    await settings.setEmoteSectionOrder(['1', 'section:7TV', 'section:Twitch']);
    await pumpEventQueue();
    expect(notified, 1);

    await Hive.close();
    Hive.init(tempDir.path);
    settings = await SettingsRepository.open();
    expect(settings.emoteSectionOrder, ['1', 'section:7TV', 'section:Twitch']);

    await settings.resetEmoteSectionOrder();
    expect(settings.emoteSectionOrder, isEmpty);

    await Hive.box<dynamic>('Settings').put(SettingsRepository.emoteSectionOrderKey, 'nonsense');
    expect(settings.emoteSectionOrder, isEmpty);
  });

  test('keeps stored settings and reads them', () async {
    final appearance = ApplicationAppearance()..themeMode = 'light';
    await stored({
      'applicationAppearance': appearance,
      'locale': 'de',
      'accentColor': 'teal',
      'recentMessagesChatHistory': false,
      'whisperHistoryHintDismissed': true,
      'emoteButtonGrayscale': true,
    });

    final settings = await SettingsRepository.open();

    expect(settings.applicationAppearance, same(appearance));
    expect(settings.locale, 'de');
    expect(settings.accent.id, 'teal');
    expect(settings.chatHistory, isFalse);
    expect(settings.whisperHistoryHintDismissed, isTrue);
    expect(settings.emoteButtonGrayscale, isTrue);
  });

  test('values of the wrong type read as the defaults instead of throwing', () async {
    await stored({
      'locale': 7,
      'accentColor': 3,
      'recentMessagesChatHistory': 'yes',
      'emoteButtonIcon': 'kappa',
      'chatSettings': 'broken',
    });

    final settings = await SettingsRepository.open();

    expect(settings.locale, isNull);
    expect(settings.accent, ColdChatTheme.defaultAccent);
    expect(settings.chatHistory, isTrue);
    expect(settings.emoteButtonIcon, isNull);
    final chatSettings = settings.chatSettings;
    expect(chatSettings.showLinkImages, ChatSettings().showLinkImages);
    // The replacement is stored, so changes to it can be saved.
    await settings.saveChatSettings(chatSettings..showLinkImages = true);
    expect((Hive.box<dynamic>('Settings').get('chatSettings') as ChatSettings).showLinkImages, isTrue);
  });

  test('saving an edited settings object persists it', () async {
    var settings = await SettingsRepository.open();
    await settings.saveChatSettings(settings.chatSettings..showLinkImages = true);
    await settings.saveMessageAppearance(settings.messageAppearance..scale = 1.5);
    await settings.saveApplicationAppearance(settings.applicationAppearance..oledBlack = true);

    await Hive.close();
    Hive.init(tempDir.path);
    settings = await SettingsRepository.open();

    expect(settings.chatSettings.showLinkImages, isTrue);
    expect(settings.messageAppearance.scale, 1.5);
    expect(settings.applicationAppearance.oledBlack, isTrue);
  });

  group('accent', () {
    test('a color from the old list moves to the closest accent', () async {
      final box = await stored({'themeColor': const Color(0xFF4CAF50).toARGB32()});

      final settings = await SettingsRepository.open();

      final expected = ColdChatTheme.closestAccent(const Color(0xFF4CAF50));
      expect(expected, isNot(ColdChatTheme.defaultAccent));
      expect(box.get('accentColor'), expected.id);
      expect(settings.accent, expected);
    });

    test('an accent that was already picked is not migrated again', () async {
      final box = await stored({'themeColor': const Color(0xFF4CAF50).toARGB32(), 'accentColor': 'red'});

      await SettingsRepository.open();

      expect(box.get('accentColor'), 'red');
    });

    test('picks an accent, and a custom one from hue and chroma', () async {
      final settings = await SettingsRepository.open();

      await settings.setAccent(ColdChatTheme.accentById('pink'));
      expect(settings.accent.id, 'pink');

      await settings.setCustomAccent(100.0, 20.0);
      expect(settings.accent.id, ColdChatTheme.customId);
      expect((settings.accent.hue, settings.accent.chroma), (100.0, 20.0));

      // The custom color is remembered while another accent is picked.
      await settings.setAccent(ColdChatTheme.defaultAccent);
      expect(settings.accent, ColdChatTheme.defaultAccent);
      expect((settings.customHue, settings.customChroma), (100.0, 20.0));
    });

    test('custom without a stored hue and chroma falls back to the default', () async {
      await stored({'accentColor': 'custom'});
      final settings = await SettingsRepository.open();

      expect(settings.accent, ColdChatTheme.defaultAccent);
    });
  });

  test('writes the locale, the chat history switch and the whisper hint', () async {
    final settings = await SettingsRepository.open();

    await settings.setLocale('fr');
    expect(settings.locale, 'fr');
    await settings.setLocale(null);
    expect(settings.locale, isNull);

    await settings.setChatHistory(false);
    expect(settings.chatHistory, isFalse);

    await settings.dismissWhisperHistoryHint();
    expect(settings.whisperHistoryHintDismissed, isTrue);
  });

  test('each listenable fires only for its own keys', () async {
    final settings = await SettingsRepository.open();
    final counts = <String, int>{};
    void count(String name) => counts[name] = (counts[name] ?? 0) + 1;
    settings.changes.addListener(() => count('all'));
    settings.appChanges.addListener(() => count('app'));
    settings.messageAppearanceChanges.addListener(() => count('message'));
    settings.chatSettingsChanges.addListener(() => count('chat'));
    settings.emoteButtonChanges.addListener(() => count('emote'));

    await settings.setLocale('de');
    await settings.saveMessageAppearance(settings.messageAppearance);
    await settings.saveChatSettings(settings.chatSettings);
    await settings.setEmoteButtonGrayscale(true);
    await settings.setCustomAccent(10.0, 10.0);
    await settings.setChatHistory(false);
    await pumpEventQueue();

    // setCustomAccent writes three keys.
    expect(counts, {'all': 8, 'app': 4, 'message': 1, 'chat': 1, 'emote': 1});
  });

  group('EmoteButtonIcon', () {
    test('is Kappa by default', () async {
      final icon = EmoteButtonIcon(await SettingsRepository.open(), api: offlineApi(), directory: tempDir);

      expect(icon.name, isNull);
      expect(icon.emoji, isNull);
      expect(icon.file, isNull);
      expect(icon.grayscale, isFalse);
    });

    test('an emoji is stored as text, the way earlier versions stored it', () async {
      final icon = EmoteButtonIcon(await SettingsRepository.open(), api: offlineApi(), directory: tempDir);
      final emoji = Emote(
        id: 'fire',
        name: 'fire',
        code: '🔥',
        mipmap: const [],
        source: EmojiSource(EmojiDataApi(offlineApi())),
      );

      await icon.set(emoji);

      expect(Hive.box<dynamic>('Settings').get('emoteButtonIcon'), {'name': 'fire', 'emoji': '🔥'});
      expect(icon.name, 'fire');
      expect(icon.emoji, '🔥');

      await icon.reset();
      expect(Hive.box<dynamic>('Settings').containsKey('emoteButtonIcon'), isFalse);
      expect(icon.name, isNull);
    });

    test('an image emote that fails to download keeps the current button', () async {
      final requests = <http.Request>[];
      final icon = EmoteButtonIcon(
        await SettingsRepository.open(),
        api: fakeApi(requests: requests, (request) async => http.Response('gone', 404)),
        directory: tempDir,
      );
      final pog = Emote(
        id: 'p',
        name: 'Pog',
        mipmap: const ['https://cdn.7tv.app/emote/p/1x.webp', 'https://cdn.7tv.app/emote/p/4x.webp'],
        source: SevenTvSource(SevenTvApi(offlineApi())),
      );

      await expectLater(icon.set(pog), throwsA(isA<HttpException>()));

      expect(requests.single.url, Uri.parse('https://cdn.7tv.app/emote/p/4x.webp'));
      expect(icon.name, isNull);
      expect(Hive.box<dynamic>('Settings').containsKey('emoteButtonIcon'), isFalse);
    });

    test('a stored image file is found in the directory', () async {
      File('${tempDir.path}/123.png').writeAsBytesSync([0]);
      await stored({
        'emoteButtonIcon': {'name': 'Pog', 'file': '123.png'},
      });
      final icon = EmoteButtonIcon(await SettingsRepository.open(), api: offlineApi(), directory: tempDir);

      expect(icon.name, 'Pog');
      expect(icon.file?.path, '${tempDir.path}/123.png');
      expect(icon.emoji, isNull);
    });

    test('grayscale is stored', () async {
      final icon = EmoteButtonIcon(await SettingsRepository.open(), api: offlineApi(), directory: tempDir);

      await icon.setGrayscale(true);

      expect(icon.grayscale, isTrue);
      expect(Hive.box<dynamic>('Settings').get('emoteButtonGrayscale'), isTrue);
    });
  });
}
