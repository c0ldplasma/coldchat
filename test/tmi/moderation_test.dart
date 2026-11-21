import 'package:coldchat/data/twitch/token_data.dart';
import 'package:coldchat/irc/message.dart' as irc;
import 'package:coldchat/tmi/badges.dart';
import 'package:coldchat/tmi/cache.dart';
import 'package:coldchat/tmi/channel/channel.dart';
import 'package:coldchat/tmi/channel/channel_event.dart';
import 'package:coldchat/tmi/client/client.dart';
import 'package:coldchat/tmi/emotes.dart';
import 'package:coldchat/tmi/moderation.dart';
import 'package:coldchat/tmi/whispers/whisper_channel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Just what a [Channel] reads from its client when it's created. The real [Client] opens connections and timers.
class _FakeClient implements Client {
  @override
  Emotes globalEmotes = Emotes();
  @override
  Badges globalBadges = Badges();
  @override
  Emotes twitchUserEmotes = Emotes();
  @override
  EmoteBadgeCache? cache;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `#ronni`, whose room id is 12826.
Channel _channel() {
  final channel = Channel(client: _FakeClient(), name: '#ronni')..id = '12826';
  addTearDown(channel.close);
  return channel;
}

/// A USERSTATE Twitch sends for `#ronni` after joining it or sending a message there, with [badges].
irc.Message _userState(String badges) => irc.Message.fromEvent(
  '@badge-info=;badges=$badges;color=#1E90FF;display-name=Moddy;emote-sets=0,300374282;mod=0;subscriber=0;'
  'user-type= :tmi.twitch.tv USERSTATE #ronni',
);

TokenData _tokenData({String? userId = '42', String? accessToken = 'access-token-1'}) => TokenData(
  clientId: 'client-id-1',
  login: 'moddy',
  scopes: const [],
  userId: userId,
  expiresAt: null,
  accessToken: accessToken,
);

void main() {
  group('hasModeratorBadge', () {
    test('is true with the moderator or the broadcaster badge', () {
      expect(hasModeratorBadge('moderator/1'), isTrue);
      expect(hasModeratorBadge('broadcaster/1'), isTrue);
      expect(hasModeratorBadge('subscriber/12,moderator/1,premium/1'), isTrue);
      expect(hasModeratorBadge('broadcaster/1,subscriber/0'), isTrue);
    });

    test('is false without either', () {
      expect(hasModeratorBadge(null), isFalse);
      expect(hasModeratorBadge(''), isFalse);
      expect(hasModeratorBadge('subscriber/12,premium/1'), isFalse);
      expect(hasModeratorBadge('vip/1'), isFalse);
      // A badge whose name only contains "moderator" doesn't count.
      expect(hasModeratorBadge('lead_moderator_test/1'), isFalse);
    });
  });

  group('Channel.applyUserState', () {
    test('a USERSTATE with the moderator badge makes the own user a moderator', () {
      final channel = _channel()..applyUserState(_userState('moderator/1,subscriber/6'));

      expect(channel.ownUserIsModerator, isTrue);
    });

    test('a USERSTATE with the broadcaster badge makes the own user a moderator', () {
      final channel = _channel()..applyUserState(_userState('broadcaster/1'));

      expect(channel.ownUserIsModerator, isTrue);
    });

    test('a later USERSTATE without the badge (unmodded) takes it away again', () {
      final channel = _channel()..applyUserState(_userState('moderator/1'));

      channel.applyUserState(_userState('subscriber/6'));

      expect(channel.ownUserIsModerator, isFalse);
    });

    test('a USERSTATE with no badges at all is not a moderator', () {
      final channel = _channel()
        ..ownUserIsModerator = true
        ..applyUserState(irc.Message.fromEvent(':tmi.twitch.tv USERSTATE #ronni'));

      expect(channel.ownUserIsModerator, isFalse);
    });
  });

  test('the transmitter parting forgets the moderator status, as the next join may be as another account', () {
    final channel = _channel()..applyUserState(_userState('moderator/1'));

    channel.transmitterParted();

    expect(channel.ownUserIsModerator, isFalse);
    expect(channel.transmitterJoin.state, isFalse);
  });

  test('the anonymous receiver parting keeps the moderator status: it is about the account', () async {
    final channel = _channel()..applyUserState(_userState('moderator/1'));

    channel.add(ChannelPart());
    await Future<void>.delayed(Duration.zero);

    expect(channel.ownUserIsModerator, isTrue);
  });

  test('USERSTATE, ROOMSTATE and NOTICE lines from the history are skipped, chat lines are kept', () {
    bool skipped(String line) => Client.skippedInHistory(irc.Message.fromEvent(line));

    expect(skipped('@badges=moderator/1 :tmi.twitch.tv USERSTATE #ronni'), isTrue);
    expect(skipped('@emote-only=0;room-id=12826;slow=0 :tmi.twitch.tv ROOMSTATE #ronni'), isTrue);
    expect(skipped('@msg-id=slow_on :tmi.twitch.tv NOTICE #ronni :This room is now in slow mode.'), isTrue);
    expect(skipped('@id=abc;user-id=1337 :ronni!ronni@ronni.tmi.twitch.tv PRIVMSG #ronni :hi'), isFalse);
    expect(skipped('@msg-id=resub;user-id=1337 :tmi.twitch.tv USERNOTICE #ronni :hi'), isFalse);
    expect(skipped(':tmi.twitch.tv CLEARCHAT #ronni :spammer'), isFalse);
  });

  group('Channel.canModerate', () {
    test('the broadcaster can moderate their own channel without a moderator badge', () {
      expect(_channel().canModerate('12826'), isTrue);
    });

    test('a moderator can moderate', () {
      final channel = _channel()..ownUserIsModerator = true;

      expect(channel.canModerate('42'), isTrue);
    });

    test('anyone else cannot', () {
      expect(_channel().canModerate('42'), isFalse);
    });

    test('without a user id nobody can, not even as a moderator', () {
      final channel = _channel()..ownUserIsModerator = true;

      expect(channel.canModerate(null), isFalse);
    });

    test('before ROOMSTATE gave the channel its id nobody can', () {
      final channel = _channel()
        ..id = null
        ..ownUserIsModerator = true;

      expect(channel.canModerate('42'), isFalse);
      expect(channel.canModerate(null), isFalse);
    });
  });

  group('canModerateAs (the delete action and the ban row)', () {
    test('is shown to a logged-in moderator', () {
      final channel = _channel()..ownUserIsModerator = true;

      expect(canModerateAs(channel, _tokenData()), isTrue);
    });

    test('is shown to the logged-in broadcaster', () {
      expect(canModerateAs(_channel(), _tokenData(userId: '12826')), isTrue);
    });

    test('is hidden from a logged-in user who is not a moderator', () {
      expect(canModerateAs(_channel(), _tokenData()), isFalse);
    });

    test('is hidden without an account or while anonymous', () {
      final channel = _channel()..ownUserIsModerator = true;

      expect(canModerateAs(channel, null), isFalse);
      // An anonymous (justinfan) account has no access token.
      expect(canModerateAs(channel, _tokenData(userId: null, accessToken: null)), isFalse);
      // The broadcaster's own login without a token doesn't count either.
      expect(canModerateAs(_channel(), _tokenData(userId: '12826', accessToken: null)), isFalse);
    });

    test('is hidden without a channel', () {
      expect(canModerateAs(null, _tokenData()), isFalse);
    });

    test('is hidden in a whisper conversation', () {
      final whisper =
          WhisperChannel(client: _FakeClient(), partnerId: '42', partnerLogin: 'moddy', partnerDisplayName: 'Moddy')
            ..id = '42'
            ..ownUserIsModerator = true;
      addTearDown(whisper.close);

      expect(canModerateAs(whisper, _tokenData()), isFalse);
    });
  });
}
