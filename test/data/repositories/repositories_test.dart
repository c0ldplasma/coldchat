import 'dart:io';

import 'package:coldchat/data/repositories/repositories.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/data/settings/chat_settings.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory tempDir;

  setUpAll(Hive.registerAdapters);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_repositories_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('deletes the file of the unused ChatSettings box', () async {
    // What every earlier version left behind: the box opened, nothing in it.
    await (await Hive.openBox<dynamic>('ChatSettings')).close();
    expect(File('${tempDir.path}/chatsettings.hive').existsSync(), isTrue);

    await Repositories.deleteUnusedBoxes();

    expect(File('${tempDir.path}/chatsettings.hive').existsSync(), isFalse);
  });

  test('without the file there is nothing to delete and nothing fails', () async {
    await Repositories.deleteUnusedBoxes();

    expect(tempDir.listSync(), isEmpty);
  });

  test('keeps the chat settings, which live in the Settings box', () async {
    final settings = await SettingsRepository.open();
    await settings.saveChatSettings(settings.chatSettings..showLinkImages = true);

    await Repositories.deleteUnusedBoxes();

    expect((Hive.box<dynamic>('Settings').get('chatSettings') as ChatSettings).showLinkImages, isTrue);
    expect(File('${tempDir.path}/settings.hive').existsSync(), isTrue);
  });
}
