import 'dart:io';

import 'package:coldchat/data/repositories/whisper_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late WhisperRepository repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('coldchat_whisper_repository_test');
    Hive.init(tempDir.path);
    repository = await WhisperRepository.open();
    box = Hive.box<dynamic>('Whispers');
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  /// A conversation as earlier versions stored it.
  Map<String, Object?> stored({bool open = true}) => {
    'login': 'friend',
    'name': 'Friend',
    'open': open,
    'unread': true,
    'openedAt': 5,
    'lines': ['line'],
  };

  test('uses the existing box and key format', () {
    expect(WhisperRepository.boxName, 'Whispers');
    expect(WhisperRepository.key('1', '2'), '1/2');
  });

  test('reads a conversation stored the way earlier versions did', () async {
    await box.put('1/2', stored());

    final conversation = repository.conversation('1', '2')!;

    expect(conversation.login, 'friend');
    expect(conversation.name, 'Friend');
    expect(conversation.open, isTrue);
    expect(conversation.unread, isTrue);
    expect(conversation.openedAt, 5);
    expect(conversation.lines, ['line']);
  });

  test('writes exactly the stored shape back', () async {
    await box.put('1/2', stored());

    await repository.save('1', '2', repository.conversation('1', '2')!);

    expect(box.get('1/2'), stored());
  });

  test('missing or broken entries read as no conversation', () async {
    await box.put('1/3', 'not a map');
    await box.put('1/4', {'login': 'nameless'});

    expect(repository.conversation('1', '2'), isNull);
    expect(repository.conversation('1', '3'), isNull);
    expect(repository.conversation('1', '4'), isNull);
  });

  test('missing fields get defaults', () async {
    await box.put('1/2', {'login': 'friend', 'name': 'Friend'});

    final conversation = repository.conversation('1', '2')!;

    expect(conversation.open, isFalse);
    expect(conversation.unread, isFalse);
    expect(conversation.openedAt, isNull);
    expect(conversation.lines, isEmpty);
  });

  test("conversationsOf lists only that account's conversations, by partner id", () async {
    await box.put('1/2', stored());
    await box.put('1/3', stored(open: false));
    await box.put('10/2', stored());
    await box.put('1/9', 'broken');

    final conversations = repository.conversationsOf('1');

    expect(conversations.keys, ['2', '3']);
    expect(conversations['3']!.open, isFalse);
  });

  test('delete removes the conversation', () async {
    await box.put('1/2', stored());

    await repository.delete('1', '2');

    expect(box.containsKey('1/2'), isFalse);
  });
}
