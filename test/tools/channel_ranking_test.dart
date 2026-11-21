import 'package:coldchat/tools/channel_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

ChannelCandidate _c(String login, {String? displayName, bool live = false, int? viewers}) => ChannelCandidate(
  login: login,
  displayName: displayName ?? login,
  profileImageUrl: 'https://example.invalid/$login.png',
  isLive: live,
  viewerCount: viewers,
);

List<String> _rank(String query, List<ChannelCandidate> candidates) => [
  for (final c in rankChannels(query, candidates)) c.login,
];

void main() {
  group('normalizeChannelQuery', () {
    test('trims spaces and drops leading # and @', () {
      expect(normalizeChannelQuery('  forsen  '), 'forsen');
      expect(normalizeChannelQuery('#forsen'), 'forsen');
      expect(normalizeChannelQuery('@forsen'), 'forsen');
      expect(normalizeChannelQuery(' ##@ forsen '), 'forsen');
    });

    test('keeps case, inner characters and a # or @ that is not leading', () {
      expect(normalizeChannelQuery('ForSen'), 'ForSen');
      expect(normalizeChannelQuery('for#sen@'), 'for#sen@');
      expect(normalizeChannelQuery('some streamer'), 'some streamer');
    });

    test('is empty for only spaces and prefixes', () {
      expect(normalizeChannelQuery(''), '');
      expect(normalizeChannelQuery('  '), '');
      expect(normalizeChannelQuery(' # '), '');
      expect(normalizeChannelQuery('@#'), '');
    });

    test('leaves twitch.tv links as they are', () {
      // Not unpacked: the search box is for names.
      expect(normalizeChannelQuery('https://twitch.tv/forsen'), 'https://twitch.tv/forsen');
    });
  });

  group('couldBeLogin', () {
    test('accepts letters, digits and underscores, up to 25 characters', () {
      expect(couldBeLogin('forsen'), isTrue);
      expect(couldBeLogin('ForSen_123'), isTrue);
      expect(couldBeLogin('a'), isTrue);
      expect(couldBeLogin('a' * 25), isTrue);
    });

    test('rejects empty, too long and anything with other characters', () {
      expect(couldBeLogin(''), isFalse);
      expect(couldBeLogin('a' * 26), isFalse);
      expect(couldBeLogin('some streamer'), isFalse);
      expect(couldBeLogin('for-sen'), isFalse);
      expect(couldBeLogin('#forsen'), isFalse);
      expect(couldBeLogin('ふぉるせん'), isFalse);
    });
  });

  group('rankChannels', () {
    test('puts the exact match first, ignoring case, even offline against big live channels', () {
      expect(
        _rank('ForSen', [
          _c('forsenlol', live: true, viewers: 50000),
          _c('forsenbajs', live: true, viewers: 100),
          _c('forsen'),
        ]),
        ['forsen', 'forsenlol', 'forsenbajs'],
      );
    });

    test('an exact display name counts as an exact match', () {
      expect(
        _rank('ふぉるせん', [
          _c('other', displayName: 'ふぉるせんファン', live: true, viewers: 10),
          _c('forsenjp', displayName: 'ふぉるせん'),
        ]),
        ['forsenjp', 'other'],
      );
    });

    test('live prefix matches before offline prefix matches before the rest', () {
      expect(
        _rank('for', [
          _c('xforsen', live: true, viewers: 99999),
          _c('fortnite'),
          _c('forsen', live: true, viewers: 10),
          _c('forx'),
          _c('xfor'),
        ]),
        ['forsen', 'forx', 'fortnite', 'xforsen', 'xfor'],
      );
    });

    test('a display name starting with the query is a prefix match', () {
      expect(
        _rank('nym', [
          _c('other'),
          _c('x_nymn', displayName: 'NymnAlt'),
        ]),
        ['x_nymn', 'other'],
      );
    });

    test('live prefix matches go by viewers, a missing count as zero, ties in Twitch order', () {
      expect(
        _rank('for', [
          _c('forb', live: true, viewers: 100),
          _c('fora', live: true),
          _c('forc', live: true, viewers: 5000),
          _c('ford', live: true, viewers: 100),
        ]),
        ['forc', 'forb', 'ford', 'fora'],
      );
    });

    test('offline prefix matches go by login length, ties in Twitch order', () {
      expect(
        _rank('for', [
          _c('forsenbajs'),
          _c('forbb'),
          _c('fora'),
          _c('foraa'),
        ]),
        ['fora', 'forbb', 'foraa', 'forsenbajs'],
      );
    });

    test('other matches (misspellings) are live before offline, otherwise in Twitch order', () {
      expect(
        _rank('forsen', [
          _c('forsne'),
          _c('fosren', live: true, viewers: 1),
          _c('frosen', live: true, viewers: 9000),
          _c('foresn'),
        ]),
        ['fosren', 'frosen', 'forsne', 'foresn'],
      );
    });

    test('does not change the given list', () {
      final candidates = [_c('forsenbajs'), _c('forsen')];
      rankChannels('forsen', candidates);
      expect([for (final c in candidates) c.login], ['forsenbajs', 'forsen']);
    });

    test('is empty for no candidates', () {
      expect(rankChannels('forsen', []), isEmpty);
    });
  });
}
