import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '/api/twitch/eventsub_socket.dart';
import '/api/twitch/twitch.dart';
import '/data/twitch_account.dart';
import '/irc/message.dart' as irc;
import '../channel/messages/channel_message_chat.dart';
import '../client/client.dart';
import 'whisper_channel.dart';

/// Thrown when a whisper can't be sent because of the account, not because of Twitch's answer.
class WhisperUnavailableException implements Exception {
  /// True when the login predates whisper support and lacks `user:manage:whispers`.
  final bool missingScope;

  WhisperUnavailableException({required this.missingScope});
}

class WhisperUserNotFoundException implements Exception {}

/// The whisper conversations shown as tabs, for the active account.
///
/// Twitch keeps no whisper history that an app can read, so every whisper sent or received here is stored on
/// the device (box `Whispers`, key `<account id>/<partner id>`), as IRC lines in the same shape as chat
/// messages. Closing a tab keeps the conversation; it comes back when the next whisper arrives.
class Whispers extends Cubit<List<WhisperChannel>> {
  static const String scope = 'user:manage:whispers';
  static const int _maxStoredMessages = 200;

  final Client client;
  final Box? box;

  WhisperChannel? active;

  final StreamController<WhisperChannel> _received = StreamController.broadcast();
  final StreamController<WhisperChannel> _focusRequests = StreamController.broadcast();

  /// Conversations that just received a whisper.
  Stream<WhisperChannel> get received => _received.stream;

  /// Conversations the UI should switch to, e.g. after "Whisper" on a user card.
  Stream<WhisperChannel> get focusRequests => _focusRequests.stream;

  TwitchAccount? _account;

  Whispers(this.client, {this.box}) : super([]);

  String? get _accountId => _account?.tokenData.accessToken == null ? null : _account!.tokenData.userId;

  /// Whether the account's login allows whispers. Logins from before whisper support lack the scope.
  bool get hasScope => _account?.tokenData.scopes.contains(scope) ?? false;

  /// Shows [account]'s open conversations, replacing the previous account's.
  void setAccount(TwitchAccount? account) {
    final sameLogin = account?.tokenData.hash == _account?.tokenData.hash && account?.tokenData.accessToken == _account?.tokenData.accessToken;
    _account = account;
    if (sameLogin) return;
    active = null;
    final previous = state;
    final accountId = _accountId;
    final conversations = <WhisperChannel>[];
    if (accountId != null && box != null) {
      for (final key in box!.keys.whereType<String>().where((key) => key.startsWith('$accountId/'))) {
        final stored = box!.get(key);
        if (stored is! Map || stored['open'] != true) continue;
        final conversation = _fromStorage(key.substring(accountId.length + 1), stored);
        conversations.add(conversation);
      }
      conversations.sortBy<num>((c) => (box!.get(_key(c)) as Map)['openedAt'] as int? ?? 0);
    }
    emit(conversations);
    for (final conversation in previous) {
      conversation.close();
    }
  }

  String _key(WhisperChannel conversation) => '$_accountId/${conversation.partnerId}';

  WhisperChannel _fromStorage(String partnerId, Map stored) {
    final conversation = WhisperChannel(
      client: client,
      partnerId: partnerId,
      partnerLogin: stored['login'] as String,
      partnerDisplayName: stored['name'] as String,
    )..unread = stored['unread'] == true;
    conversation.channelMessages.beginBulk();
    for (final line in (stored['lines'] as List? ?? const []).cast<String>()) {
      _addLine(conversation, line);
    }
    conversation.channelMessages.endBulk();
    return conversation;
  }

  void _addLine(WhisperChannel conversation, String line) {
    try {
      final message = irc.Message.fromEvent(line);
      conversation.channelMessages.add(ChannelMessageChat(
        message: message,
        dateTime: DateTime.fromMillisecondsSinceEpoch(int.tryParse(message.tags['tmi-sent-ts'] ?? '') ?? DateTime.now().millisecondsSinceEpoch),
        channel: conversation,
      ));
    } catch (_) {
      // A corrupt stored line is not worth losing the conversation over.
    }
  }

  void _save(WhisperChannel conversation, {required bool open, String? addLine}) {
    final store = box;
    if (store == null || _accountId == null) return;
    final key = _key(conversation);
    final stored = store.get(key);
    final lines = [...(stored is Map ? (stored['lines'] as List? ?? const []).cast<String>() : const <String>[])];
    if (addLine != null) lines.add(addLine);
    final wasOpen = stored is Map && stored['open'] == true;
    store.put(key, {
      'login': conversation.partnerLogin,
      'name': conversation.partnerDisplayName,
      'open': open,
      'unread': conversation.unread,
      'openedAt': wasOpen && open ? stored['openedAt'] : DateTime.now().millisecondsSinceEpoch,
      'lines': lines.length > _maxStoredMessages ? lines.sublist(lines.length - _maxStoredMessages) : lines,
    });
  }

  /// The conversation with the given user, opening its tab if needed.
  WhisperChannel _conversation({required String partnerId, required String login, required String displayName}) {
    final existing = state.firstWhereOrNull((c) => c.partnerId == partnerId);
    if (existing != null) {
      existing.partnerLogin = login;
      existing.partnerDisplayName = displayName;
      return existing;
    }
    final stored = box?.get('$_accountId/$partnerId');
    final conversation = stored is Map
        ? _fromStorage(partnerId, stored)
        : WhisperChannel(client: client, partnerId: partnerId, partnerLogin: login, partnerDisplayName: displayName);
    conversation.partnerLogin = login;
    conversation.partnerDisplayName = displayName;
    _save(conversation, open: true);
    emit([...state, conversation]);
    return conversation;
  }

  /// Opens (or reuses) the conversation with [login], looking the user up on Twitch.
  Future<WhisperChannel> open(String login) async {
    final tokenData = _account?.tokenData;
    if (tokenData == null || tokenData.accessToken == null) throw WhisperUnavailableException(missingScope: false);
    login = login.replaceFirst('@', '').toLowerCase();
    final existing = state.firstWhereOrNull((c) => c.partnerLogin == login);
    if (existing != null) return existing;
    final users = await Twitch.usersByLogin(tokenData, [login]);
    final user = users.firstOrNull;
    if (user == null) throw WhisperUserNotFoundException();
    return _conversation(partnerId: user.id, login: user.login, displayName: user.displayName);
  }

  /// Opens the conversation with [login] and asks the UI to switch to it.
  Future<WhisperChannel> openAndFocus(String login) async {
    final conversation = await open(login);
    _focusRequests.add(conversation);
    return conversation;
  }

  /// Sends [text] to the conversation's user. Throws [WhisperUnavailableException] or
  /// [TwitchRequestException] (with Twitch's reason, e.g. an unverified phone number) when it isn't sent.
  Future<void> send(WhisperChannel conversation, String text) async {
    text = text.trim();
    if (text.isEmpty) return;
    final account = _account;
    final tokenData = account?.tokenData;
    if (account == null || tokenData == null || tokenData.accessToken == null || tokenData.userId == null) {
      throw WhisperUnavailableException(missingScope: false);
    }
    if (!hasScope) throw WhisperUnavailableException(missingScope: true);
    await Twitch.sendWhisper(tokenData, toUserId: conversation.partnerId, message: text);
    final line = _line(
      id: 'sent-${DateTime.now().microsecondsSinceEpoch}',
      userId: tokenData.userId!,
      login: tokenData.login,
      displayName: account.userData?.displayName ?? tokenData.login,
      color: client.ownColor,
      partnerLogin: conversation.partnerLogin,
      text: text,
    );
    _addLine(conversation, line);
    _save(conversation, open: true, addLine: line);
  }

  /// `/w <login> <message>`: opens the conversation and sends the message there.
  Future<WhisperChannel> sendTo(String login, String text) async {
    final conversation = await open(login);
    await send(conversation, text);
    return conversation;
  }

  void receive(ReceivedWhisper whisper) {
    if (_accountId == null) return;
    final conversation = _conversation(partnerId: whisper.fromUserId, login: whisper.fromLogin, displayName: whisper.fromDisplayName);
    final line = _line(
      id: whisper.id,
      userId: whisper.fromUserId,
      login: whisper.fromLogin,
      displayName: whisper.fromDisplayName,
      color: client.chatColorOf(whisper.fromUserId),
      partnerLogin: whisper.fromLogin,
      text: whisper.text,
    );
    _addLine(conversation, line);
    if (active != conversation) conversation.unread = true;
    _save(conversation, open: true, addLine: line);
    emit([...state]);
    _received.add(conversation);
  }

  void markRead(WhisperChannel conversation) {
    if (!conversation.unread) return;
    conversation.unread = false;
    _save(conversation, open: true);
    emit([...state]);
  }

  /// Closes the tab. The conversation stays on the device and reopens with the next whisper.
  void closeConversation(WhisperChannel conversation) {
    conversation.unread = false;
    _save(conversation, open: false);
    _remove(conversation);
  }

  /// Closes the tab and deletes the stored messages.
  void deleteConversation(WhisperChannel conversation) {
    if (_accountId != null) box?.delete(_key(conversation));
    _remove(conversation);
  }

  void _remove(WhisperChannel conversation) {
    if (active == conversation) active = null;
    emit([...state.where((c) => c != conversation)]);
    conversation.close();
  }

  // Whispers are kept in the same IRC form as chat, so they render and store like it. The channel parameter
  // is the partner, which nothing reads.
  static String _line({
    required String id,
    required String userId,
    required String login,
    required String displayName,
    required String? color,
    required String partnerLogin,
    required String text,
  }) {
    String tag(String value) => value.replaceAll(RegExp(r'[;\s]'), '');
    final body = text.replaceAll(RegExp(r'[\r\n]+'), ' ');
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '@id=${tag(id)};user-id=${tag(userId)};display-name=${tag(displayName)};color=${tag(color ?? '')};tmi-sent-ts=$ts '
        ':$login!$login@$login.tmi.twitch.tv PRIVMSG @$partnerLogin :$body';
  }

  @override
  Future<void> close() {
    _received.close();
    _focusRequests.close();
    return super.close();
  }
}
