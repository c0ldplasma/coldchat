import 'package:coldchat/tmi/channel/channel_message.dart';
import 'package:coldchat/tmi/channel/channel_messages.dart';
import 'package:coldchat/tmi/channel/messages/channel_message_id.dart';
import 'package:flutter_test/flutter_test.dart';

/// A message with an id, at second [second].
class _Chat extends ChannelMessage with ChannelMessageId {
  _Chat(String id, int second) : super(dateTime: DateTime(2026, 11, 21).add(Duration(seconds: second))) {
    this.id = id;
  }

  @override
  String toString() => id;
}

/// A message without an id (like a local notice), never deduplicated.
class _Notice extends ChannelMessage {
  _Notice(this.name, int second) : super(dateTime: DateTime(2026, 11, 21).add(Duration(seconds: second)));

  final String name;

  @override
  String toString() => name;
}

ChannelMessages _messages() {
  final messages = ChannelMessages();
  addTearDown(messages.close);
  return messages;
}

List<String> _names(ChannelMessages messages) => [for (final message in messages.state) '$message'];

void main() {
  group('add', () {
    test('appends messages that arrive in order', () {
      final messages = _messages()
        ..add(_Chat('a', 1))
        ..add(_Chat('b', 2))
        ..add(_Chat('c', 3));

      expect(_names(messages), ['a', 'b', 'c']);
    });

    test('puts an older message at its place by time', () {
      final messages = _messages()
        ..add(_Chat('a', 1))
        ..add(_Chat('c', 3))
        ..add(_Chat('b', 2))
        ..add(_Chat('first', 0));

      expect(_names(messages), ['first', 'a', 'b', 'c']);
    });

    test('keeps messages with the same time in the order they arrived', () {
      final messages = _messages()
        ..add(_Chat('a', 1))
        ..add(_Chat('b', 1))
        ..add(_Notice('n', 1))
        ..add(_Chat('c', 1));

      expect(_names(messages), ['a', 'b', 'n', 'c']);
    });

    test('ignores a message whose id is already there, but never one without an id', () {
      final messages = _messages()
        ..add(_Chat('a', 1))
        ..add(_Chat('a', 2))
        ..add(_Notice('n', 3))
        ..add(_Notice('n', 3));

      expect(_names(messages), ['a', 'n', 'n']);
    });

    test('emits a new list every time', () {
      final messages = _messages()..add(_Chat('a', 1));
      final before = messages.state;

      messages.add(_Chat('b', 2));

      expect(messages.state, isNot(same(before)));
      expect(before, hasLength(1));
    });

    test('keeps the newest ${ChannelMessages.limit} and forgets the ids of the dropped ones', () {
      final messages = _messages();
      for (var i = 0; i < ChannelMessages.limit + 5; i++) {
        messages.add(_Chat('m$i', i));
      }

      expect(messages.state, hasLength(ChannelMessages.limit));
      expect(_names(messages).first, 'm5');
      expect(_names(messages).last, 'm${ChannelMessages.limit + 4}');

      // A kept message can't come back twice.
      messages.add(_Chat('m5', 5));
      expect(_names(messages).where((name) => name == 'm5'), hasLength(1));

      // A dropped one can (as before); it pushes out the oldest kept one.
      messages.add(_Chat('m0', 0));
      expect(_names(messages).take(2), ['m0', 'm6']);
      expect(messages.state, hasLength(ChannelMessages.limit));
    });
  });

  group('replace', () {
    test('swaps the previous message for the next one in one emit', () {
      final messages = _messages()
        ..add(_Chat('a', 1))
        ..add(_Chat('pending', 2));
      final emitted = <List<String>>[];
      final subscription = messages.stream.listen((state) => emitted.add([for (final m in state) '$m']));
      addTearDown(subscription.cancel);

      messages.replace(messages.state.last, _Chat('sent', 2));

      return Future<void>.delayed(Duration.zero, () {
        expect(emitted, [
          ['a', 'sent'],
        ]);
      });
    });

    test('forgets the id of the previous message', () {
      final messages = _messages()..add(_Chat('a', 1));

      messages
        ..replace(messages.state.single, _Chat('b', 1))
        ..add(_Chat('a', 2));

      expect(_names(messages), ['b', 'a']);
    });

    test('ignores a next message whose id is already there', () {
      final messages = _messages()
        ..add(_Chat('a', 1))
        ..add(_Chat('b', 2));

      messages.replace(messages.state.first, _Chat('b', 3));

      expect(_names(messages), ['a', 'b']);
    });

    test('just adds when there is no previous message', () {
      final messages = _messages()..add(_Chat('a', 1));

      messages.replace(null, _Chat('b', 2));

      expect(_names(messages), ['a', 'b']);
    });
  });

  group('bulk', () {
    test('emits once, sorted and without duplicates, and keeps the ids for later adds', () {
      final messages = _messages()..add(_Chat('live', 10));
      var emits = 0;
      final subscription = messages.stream.listen((_) => emits++);
      addTearDown(subscription.cancel);

      messages
        ..beginBulk()
        ..add(_Chat('h2', 2))
        ..add(_Chat('h1', 1))
        ..add(_Chat('live', 10))
        ..add(_Chat('h1', 1))
        ..endBulk()
        ..add(_Chat('h2', 2));

      expect(_names(messages), ['h1', 'h2', 'live']);
      return Future<void>.delayed(Duration.zero, () => expect(emits, 1));
    });

    test('keeps only the newest ${ChannelMessages.limit}', () {
      final messages = _messages()..beginBulk();
      for (var i = ChannelMessages.limit + 9; i >= 0; i--) {
        messages.add(_Chat('m$i', i));
      }
      messages
        ..endBulk()
        ..add(_Chat('m0', 0));

      expect(messages.state, hasLength(ChannelMessages.limit));
      expect(_names(messages).first, 'm0');
      expect(_names(messages)[1], 'm11');
    });
  });

  test('refresh emits the same messages as a new list', () {
    final messages = _messages()..add(_Chat('a', 1));
    final before = messages.state;

    messages.refresh();

    expect(messages.state, isNot(same(before)));
    expect(_names(messages), ['a']);
  });
}
