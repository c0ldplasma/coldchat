import 'package:coldchat/widgets/chat/composer_send.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseWhisperCommand', () {
    test('/w with only a user has no message', () {
      expect(parseWhisperCommand('/w ronni'), (login: 'ronni', message: ''));
      expect(parseWhisperCommand('/w ronni   '), (login: 'ronni', message: ''));
    });

    test('drops the @ before the user and trims the message', () {
      expect(parseWhisperCommand('/w @ronni hello there '), (login: 'ronni', message: 'hello there'));
      expect(parseWhisperCommand('/w ronni    hi'), (login: 'ronni', message: 'hi'));
    });

    test('/whisper works too and keeps line breaks in the message', () {
      expect(parseWhisperCommand('/whisper ronni multi\nline'), (login: 'ronni', message: 'multi\nline'));
      expect(parseWhisperCommand('/w\nronni\nhi'), (login: 'ronni', message: 'hi'));
    });

    test('ignores whitespace around the command', () {
      expect(parseWhisperCommand('   /w ronni hi'), (login: 'ronni', message: 'hi'));
      expect(parseWhisperCommand('\n/w ronni hi\n'), (login: 'ronni', message: 'hi'));
    });

    test('is null for anything else', () {
      expect(parseWhisperCommand('/wx ronni hi'), isNull);
      expect(parseWhisperCommand('/whisperx ronni'), isNull);
      expect(parseWhisperCommand('/W ronni hi'), isNull);
      expect(parseWhisperCommand('/w'), isNull);
      expect(parseWhisperCommand('/w   '), isNull);
      expect(parseWhisperCommand('w ronni hi'), isNull);
      expect(parseWhisperCommand('hello /w ronni'), isNull);
      expect(parseWhisperCommand('hello chat'), isNull);
      expect(parseWhisperCommand(''), isNull);
    });
  });

  group('composerSendFor', () {
    ComposerSend send(String text, {bool isWhisperChannel = false, bool canSend = true}) =>
        composerSendFor(text, isWhisperChannel: isWhisperChannel, canSend: canSend);

    test('a whisper command opens or whispers, in any tab and even when not connected', () {
      for (final isWhisperChannel in [false, true]) {
        for (final canSend in [false, true]) {
          final open = send('/w @ronni', isWhisperChannel: isWhisperChannel, canSend: canSend);
          expect(open, isA<OpenWhisper>().having((a) => a.login, 'login', 'ronni'));
          final whisper = send('/w ronni hi', isWhisperChannel: isWhisperChannel, canSend: canSend);
          expect(
            whisper,
            isA<SendWhisper>().having((a) => a.login, 'login', 'ronni').having((a) => a.message, 'message', 'hi'),
          );
        }
      }
    });

    test('a whisper conversation sends other text there, even when the channel could not send', () {
      expect(send('hi', isWhisperChannel: true, canSend: false), isA<SendInWhisperChannel>());
      expect(send('hi', isWhisperChannel: true), isA<SendInWhisperChannel>());
    });

    test('a channel sends only when connected', () {
      expect(send('hi'), isA<SendToChannel>());
      expect(send('hi', canSend: false), isA<NotConnected>());
      expect(send('/wx ronni hi', canSend: false), isA<NotConnected>());
    });
  });
}
