import 'dart:io';

import 'package:coldchat/data/repositories/channel_repository.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory tempDir;

  setUpAll(Hive.registerAdapters);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_channel_repository_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('uses the existing boxes and keys', () {
    expect(ChannelRepository.boxName, 'Channels');
    expect(ChannelRepository.settingsBoxName, 'Settings');
    expect(ChannelRepository.lastChannelKey, 'lastChannel');
  });

  test('reads channels and the last channel stored the way earlier versions did', () async {
    await (await Hive.openBox<dynamic>('Channels')).addAll(['forsen', 'nymn']);
    await (await Hive.openBox<dynamic>('Settings')).put('lastChannel', 'nymn');

    final repository = await ChannelRepository.open();

    expect(repository.channels, ['forsen', 'nymn']);
    expect(repository.lastChannel, 'nymn');
  });

  test('nothing stored yet', () async {
    final repository = await ChannelRepository.open();

    expect(repository.channels, isEmpty);
    expect(repository.lastChannel, isNull);
  });

  test('adds and removes channels, keeping the order', () async {
    final repository = await ChannelRepository.open();

    await repository.add('a');
    await repository.addAll(['b', 'c']);
    expect(repository.channels, ['a', 'b', 'c']);

    await repository.remove('b');
    expect(repository.channels, ['a', 'c']);

    // Removing one that isn't open does nothing.
    await repository.remove('zzz');
    expect(repository.channels, ['a', 'c']);

    await Hive.close();
    Hive.init(tempDir.path);
    expect((await ChannelRepository.open()).channels, ['a', 'c']);
  });

  test('removes only the first entry of a channel stored twice', () async {
    final repository = await ChannelRepository.open();
    await repository.addAll(['a', 'b', 'a']);

    await repository.remove('a');

    expect(repository.channels, ['b', 'a']);
  });

  test('shares the Settings box with SettingsRepository when both are opened at once', () async {
    final (channels, settings) = await (ChannelRepository.open(), SettingsRepository.open()).wait;
    var settingsChanges = 0;
    var appChanges = 0;
    settings.changes.addListener(() => settingsChanges++);
    settings.appChanges.addListener(() => appChanges++);

    await channels.setLastChannel('forsen');
    await pumpEventQueue();

    // Switching tabs writes the last channel, which must not rebuild the whole app.
    expect((settingsChanges, appChanges), (1, 0));
  });

  test('stores the last channel in the Settings box', () async {
    final repository = await ChannelRepository.open();

    await repository.setLastChannel('@friend');

    expect(repository.lastChannel, '@friend');
    expect(Hive.box<dynamic>('Settings').get('lastChannel'), '@friend');
  });
}
