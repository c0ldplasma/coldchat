import 'package:coldchat/api/twitch/twitch.dart';
import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/modal/message.dart';
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
