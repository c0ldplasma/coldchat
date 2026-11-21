import 'package:coldchat/api/twitch/twitch.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/modal/message.dart';
import 'package:coldchat/modal/user.dart';
import 'package:coldchat/tmi/whispers/whispers.dart';
import 'package:coldchat/widgets/channel_view.dart';
import 'package:flutter_test/flutter_test.dart';

TokenData _token(List<String> scopes) => TokenData(
  clientId: 'client',
  login: 'someone',
  scopes: scopes,
  userId: '1',
  expiresAt: null,
  accessToken: 'token',
);

void main() {
  group('deleting a message', () {
    test('needs a login with the delete scope', () {
      expect(canDeleteMessagesWith(null), isFalse);
      expect(canDeleteMessagesWith(_token(['chat:read', 'chat:edit'])), isFalse);
      expect(canDeleteMessagesWith(_token(['chat:read', Twitch.deleteChatMessageScope])), isTrue);
    });

    test('offers to sign in again only on a 401', () {
      expect(deleteFailureNeedsSignIn(TwitchRequestException(401, 'Missing scope')), isTrue);
      expect(deleteFailureNeedsSignIn(TwitchRequestException(403, 'Not a moderator')), isFalse);
      expect(deleteFailureNeedsSignIn(TwitchRequestException(500, 'Server error')), isFalse);
      expect(deleteFailureNeedsSignIn(Exception('offline')), isFalse);
    });
  });

  group('banning, timing out and unbanning', () {
    const scope = 'moderator:manage:banned_users';

    test('without a login offers to log in', () {
      expect(moderationBlocker(null, broadcasterId: '2'), ModerationBlocker.needsLogin);
      expect(moderationBlocker(_token([scope]), broadcasterId: null), ModerationBlocker.needsLogin);
      final noUserId = _token([scope])..userId = null;
      expect(moderationBlocker(noUserId, broadcasterId: '2'), ModerationBlocker.needsLogin);
    });

    test('without the scope offers to sign in again', () {
      expect(moderationBlocker(_token(['chat:read', 'chat:edit']), broadcasterId: '2'), ModerationBlocker.needsScope);
    });

    test('with the scope tries the request, whose failures get no button', () {
      expect(moderationBlocker(_token(['chat:read', scope]), broadcasterId: '2'), isNull);
    });
  });

  group('whisper errors', () {
    test('offer to sign in only when the login is missing or lacks the scope', () {
      expect(ChannelViewState.whisperErrorNeedsSignIn(WhisperUnavailableException(missingScope: true)), isTrue);
      expect(ChannelViewState.whisperErrorNeedsSignIn(WhisperUnavailableException(missingScope: false)), isTrue);
      expect(ChannelViewState.whisperErrorNeedsSignIn(WhisperUserNotFoundException()), isFalse);
      expect(ChannelViewState.whisperErrorNeedsSignIn(TwitchRequestException(401, 'Unauthorized')), isFalse);
      expect(ChannelViewState.whisperErrorNeedsSignIn(Exception('offline')), isFalse);
    });
  });
}
