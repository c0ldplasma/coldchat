import 'dart:io';

import 'package:coldchat/app.dart';
import 'package:coldchat/data/emote_button_icon.dart';
import 'package:coldchat/data/filesharing/upload_queue_cubit.dart';
import 'package:coldchat/data/notifications_cubit.dart';
import 'package:coldchat/data/repositories/account_repository.dart';
import 'package:coldchat/data/repositories/channel_repository.dart';
import 'package:coldchat/data/repositories/custom_command_repository.dart';
import 'package:coldchat/data/repositories/settings_repository.dart';
import 'package:coldchat/data/settings/application_appearance.dart';
import 'package:coldchat/data/settings/chat_settings.dart';
import 'package:coldchat/data/settings/message_appearance.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/connection/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import 'api/fake_api.dart';
import 'tmi/client/fake_client.dart';

/// No last shown channel.
class _FakeChannelRepository implements ChannelRepository {
  @override
  String? lastChannel;

  @override
  Future<void> setLastChannel(String name) async => lastChannel = name;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;
  // Made outside the tests' fake time: a connection starts a periodic watchdog the tests would report as pending.
  late Connection transmitter;

  setUpAll(() async {
    transmitter = Connection(name: 'transmitter');
    Hive.registerAdapters();
    tempDir = Directory.systemTemp.createTempSync('coldchat_app_test');
    Hive.init(tempDir.path);
    final settings = await Hive.openBox<dynamic>('Settings');
    // Stored up front: a setting read for the first time is written to the box, and a write started in a test's fake
    // time never finishes, which would keep Hive from closing.
    await settings.put(SettingsRepository.messageAppearanceKey, MessageAppearance());
    await settings.put(SettingsRepository.chatSettingsKey, ChatSettings());
    await settings.put(SettingsRepository.applicationAppearanceKey, ApplicationAppearance());
    await Hive.openBox<dynamic>('AccountSettings');
    await Hive.openBox<dynamic>('TwitchAccounts');
    await Hive.openBox<dynamic>(CustomCommandRepository.boxName);
  });

  tearDownAll(() async {
    await transmitter.close();
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('the app listens to the client while shown and stops when it is removed', (tester) async {
    final client = FakeClient(transmitter: transmitter);
    addTearDown(client.closeFocusRequests);
    addTearDown(client.whispers.close);
    addTearDown(client.channels.close);
    final notifications = NotificationsCubit();
    addTearDown(notifications.close);
    final uploads = UploadQueueCubit(api: offlineApi());
    addTearDown(uploads.close);
    final settings = SettingsRepository(Hive.box<dynamic>('Settings'));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<Client>.value(value: client),
          Provider<ChannelRepository>.value(value: _FakeChannelRepository()),
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
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    expect(client.listeners, hasLength(1));

    // Removing the app disposes it; it must not look up the client through its deactivated context then.
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    expect(client.listeners, isEmpty);
  });
}
