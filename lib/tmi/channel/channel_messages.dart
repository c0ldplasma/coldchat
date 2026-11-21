import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';

import 'channel_message.dart';
import 'messages/channel_message_id.dart';

/// A channel's messages, oldest first, at most [limit] of them.
///
/// Every change emits a new list (a cubit only notifies for a new state), but a single message is put at its place
/// by binary search instead of sorting the whole list again, and duplicates are found in [_ids] instead of by
/// scanning it.
class ChannelMessages extends Cubit<List<ChannelMessage>> {
  ChannelMessages() : super([]);

  static const int limit = 1000;

  /// Sorts [messages] by time, in place. Stable: messages with the same time keep the order they were added in.
  static List<ChannelMessage> sort(List<ChannelMessage> messages) {
    mergeSort(messages, compare: (a, b) => a.dateTime.compareTo(b.dateTime));
    return messages;
  }

  /// The ids of the [ChannelMessageId] messages in [state].
  Set<String> _ids = {};

  static String? _idOf(ChannelMessage message) => message is ChannelMessageId ? (message as ChannelMessageId).id : null;

  // While deferring, add() mutates the working list without emitting so a
  // bulk history insert produces a single rebuild instead of one per message
  // (which made the chat visibly scroll through every message as it loaded).
  // A companion id set keeps dedup O(1) across a large bulk insert.
  bool _deferEmit = false;
  List<ChannelMessage>? _deferredState;
  Set<String>? _deferredIds;

  void beginBulk() {
    _deferEmit = true;
    _deferredState = [...state];
    _deferredIds = {..._ids};
  }

  void endBulk() {
    _deferEmit = false;
    final pending = _deferredState;
    _deferredState = null;
    _deferredIds = null;
    if (pending == null) return;
    sort(pending);
    _emitWithIds(pending.length > limit ? pending.sublist(pending.length - limit) : pending);
  }

  void add(ChannelMessage message) {
    final id = _idOf(message);
    if (_deferEmit) {
      if (id != null && !_deferredIds!.add(id)) return;
      _deferredState!.add(message);
      return;
    }
    if (id != null && _ids.contains(id)) return;
    _insert(state, message);
  }

  /// Atomically swap [previous] for [next] in a single emit so the UI never
  /// observes the intermediate list without either entry (avoids the visible
  /// jump that two separate remove/add emits would cause).
  void replace(ChannelMessage? previous, ChannelMessage next) {
    final id = _idOf(next);
    if (id != null && _ids.contains(id)) return;
    if (previous == null || !state.contains(previous)) return _insert(state, next);
    final previousId = _idOf(previous);
    if (previousId != null) _ids.remove(previousId);
    _insert([...state]..remove(previous), next);
  }

  /// Emits the same messages again, e.g. after they were rebuilt with new emotes or badges.
  void refresh() => emit([...state]);

  /// Emits [messages] with [message] at its place by time (after those with the same time), dropping the oldest of
  /// [messages] first if they're already at the [limit].
  void _insert(List<ChannelMessage> messages, ChannelMessage message) {
    final dropped = messages.length >= limit ? messages.length - limit + 1 : 0;
    for (final old in messages.take(dropped)) {
      final oldId = _idOf(old);
      if (oldId != null) _ids.remove(oldId);
    }
    final kept = dropped == 0 ? messages : messages.sublist(dropped);
    // The first message newer than [message]; usually none, as chat arrives in order.
    var low = 0;
    var high = kept.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (kept[middle].dateTime.compareTo(message.dateTime) <= 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final id = _idOf(message);
    if (id != null) _ids.add(id);
    emit([...kept.take(low), message, ...kept.skip(low)]);
  }

  void _emitWithIds(List<ChannelMessage> messages) {
    _ids = {for (final message in messages) ?_idOf(message)};
    emit(messages);
  }
}
