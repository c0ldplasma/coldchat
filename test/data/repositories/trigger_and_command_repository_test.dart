import 'dart:io';

import 'package:coldchat/data/custom_command.dart';
import 'package:coldchat/data/message_trigger.dart';
import 'package:coldchat/data/repositories/custom_command_repository.dart';
import 'package:coldchat/data/repositories/trigger_repository.dart';
import 'package:coldchat/data/user_trigger.dart';
import 'package:coldchat/hive_registrar.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory tempDir;

  setUpAll(Hive.registerAdapters);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('coldchat_trigger_repository_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> reopen() async {
    await Hive.close();
    Hive.init(tempDir.path);
  }

  group('TriggerRepository', () {
    test('uses the existing boxes', () {
      expect(TriggerRepository.messageTriggersBoxName, 'MessageTriggers');
      expect(TriggerRepository.userTriggersBoxName, 'UserTriggers');
    });

    test('reads triggers stored the way earlier versions did', () async {
      await (await Hive.openBox<dynamic>('MessageTriggers'))
          .add(MessageTrigger(type: MessageTriggerType.mention.index, pattern: 'hello'));
      await (await Hive.openBox<dynamic>('UserTriggers'))
          .add(UserTrigger(type: UserTriggerType.mention.index, login: 'Friend'));

      final repository = await TriggerRepository.open();

      expect(repository.messageTriggers.single.pattern, 'hello');
      expect(repository.userTriggers.single.login, 'Friend');
    });

    test('adds, edits and deletes triggers', () async {
      var repository = await TriggerRepository.open();
      await repository.addMessageTrigger(MessageTrigger(type: MessageTriggerType.mention.index, pattern: 'a'));
      await repository.addMessageTrigger(MessageTrigger(type: MessageTriggerType.mention.index, pattern: 'b'));
      await repository.addUserTrigger(UserTrigger(type: UserTriggerType.mention.index, login: 'x'));

      final edited = repository.messageTriggers.first..pattern = 'A';
      await repository.saveMessageTrigger(edited);
      final user = repository.userTriggers.single..type = UserTriggerType.block.index;
      await repository.saveUserTrigger(user);
      await repository.deleteMessageTrigger(repository.messageTriggers.last);

      await reopen();
      repository = await TriggerRepository.open();
      expect([for (final t in repository.messageTriggers) t.pattern], ['A']);
      expect(repository.userTriggers.single.type, UserTriggerType.block.index);

      await repository.deleteUserTrigger(repository.userTriggers.single);
      expect(repository.userTriggers, isEmpty);
    });

    test('userTriggerFor finds the first trigger for a login, ignoring case', () async {
      final repository = await TriggerRepository.open();
      await repository.addUserTrigger(UserTrigger(type: UserTriggerType.mention.index, login: 'Friend'));
      await repository.addUserTrigger(UserTrigger(type: UserTriggerType.block.index, login: 'friend'));

      expect(repository.userTriggerFor('FRIEND')?.type, UserTriggerType.mention.index);
      expect(repository.userTriggerFor('stranger'), isNull);
      expect(repository.userTriggerFor(null), isNull);
    });

    test('saves several message triggers entered at once', () async {
      var repository = await TriggerRepository.open();
      await repository.saveMessageTriggerEntries([
        (pattern: 'a', enableRegex: false, caseSensitive: false),
        (pattern: 'b|c', enableRegex: true, caseSensitive: true),
      ], type: MessageTriggerType.block);

      await reopen();
      repository = await TriggerRepository.open();
      expect(
        [for (final t in repository.messageTriggers) (t.pattern, t.enableRegex, t.caseSensitive, t.type)],
        [
          ('a', false, false, MessageTriggerType.block.index),
          ('b|c', true, true, MessageTriggerType.block.index),
        ],
      );
    });

    test('editing a message trigger into several lines keeps it and adds the rest', () async {
      final repository = await TriggerRepository.open();
      await repository.addMessageTrigger(MessageTrigger(type: MessageTriggerType.mention.index, pattern: 'old'));
      await repository.addMessageTrigger(MessageTrigger(type: MessageTriggerType.mention.index, pattern: 'other'));

      await repository.saveMessageTriggerEntries(
        [
          (pattern: 'new', enableRegex: true, caseSensitive: false),
          (pattern: 'extra', enableRegex: false, caseSensitive: false),
        ],
        type: MessageTriggerType.mention,
        existing: repository.messageTriggers.first,
      );

      expect([for (final t in repository.messageTriggers) t.pattern], ['new', 'other', 'extra']);
      expect(repository.messageTriggers.first.enableRegex, isTrue);
    });

    test('saves several user triggers entered at once, editing the first', () async {
      final repository = await TriggerRepository.open();
      await repository.addUserTrigger(UserTrigger(type: UserTriggerType.mention.index, login: 'old'));

      await repository.saveUserTriggerLogins(
        ['alice', 'bob'],
        type: UserTriggerType.block,
        existing: repository.userTriggers.single,
      );
      await repository.saveUserTriggerLogins(['carol'], type: UserTriggerType.mention);

      expect(
        [for (final t in repository.userTriggers) (t.login, t.type)],
        [
          ('alice', UserTriggerType.block.index),
          ('bob', UserTriggerType.block.index),
          ('carol', UserTriggerType.mention.index),
        ],
      );
    });

    test('each list has its own listenable', () async {
      final repository = await TriggerRepository.open();
      var messageChanges = 0;
      var userChanges = 0;
      repository.messageTriggerChanges.addListener(() => messageChanges++);
      repository.userTriggerChanges.addListener(() => userChanges++);

      await repository.addMessageTrigger(MessageTrigger(type: MessageTriggerType.mention.index, pattern: 'a'));
      await pumpEventQueue();
      expect((messageChanges, userChanges), (1, 0));

      await repository.addUserTrigger(UserTrigger(type: UserTriggerType.mention.index, login: 'x'));
      await pumpEventQueue();
      expect((messageChanges, userChanges), (1, 1));
    });
  });

  group('CustomCommandRepository', () {
    test('uses the existing box', () {
      expect(CustomCommandRepository.boxName, 'CustomCommands');
    });

    test('reads commands stored the way earlier versions did', () async {
      await (await Hive.openBox<dynamic>('CustomCommands')).add(CustomCommand(trigger: '/hi', command: 'Hello'));

      final repository = await CustomCommandRepository.open();

      expect(repository.commands.single.command, 'Hello');
    });

    test('adds, edits and deletes commands', () async {
      var repository = await CustomCommandRepository.open();
      await repository.add(CustomCommand(trigger: '/a', command: 'A'));
      await repository.add(CustomCommand(trigger: '/b', command: 'B'));

      await repository.save(repository.commands.first..command = 'AA');
      await repository.delete(repository.commands.last);

      await reopen();
      repository = await CustomCommandRepository.open();
      expect([for (final c in repository.commands) '${c.trigger} ${c.command}'], ['/a AA']);
    });

    test('commandFor and commandsStartingWith ignore case', () async {
      final repository = await CustomCommandRepository.open();
      await repository.add(CustomCommand(trigger: '/Hello', command: 'Hello chat'));
      await repository.add(CustomCommand(trigger: '/help', command: 'Ask a mod'));
      await repository.add(CustomCommand(trigger: '/bye', command: 'Bye'));

      expect(repository.commandFor('/HELLO')?.command, 'Hello chat');
      expect(repository.commandFor('/hel'), isNull);
      expect([for (final c in repository.commandsStartingWith('/HE')) c.trigger], ['/Hello', '/help']);
    });

    test('changes fires when a command is added', () async {
      final repository = await CustomCommandRepository.open();
      var changes = 0;
      repository.changes.addListener(() => changes++);

      await repository.add(CustomCommand(trigger: '/a', command: 'A'));
      await pumpEventQueue();

      expect(changes, 1);
    });
  });
}
