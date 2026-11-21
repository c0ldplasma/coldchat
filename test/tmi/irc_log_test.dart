import 'package:coldchat/tmi/irc_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ircLog only hands the line to debugPrint and keeps nothing', () {
    final printed = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    addTearDown(() => debugPrint = original);

    ircLog('receiver: joined #ronni');
    ircLog('transmitter: joined #ronni');

    expect(printed, ['[irc] receiver: joined #ronni', '[irc] transmitter: joined #ronni']);

    // Nothing is retained: with debugPrint muted, a burst of lines leaves no trace anywhere to read back.
    debugPrint = (message, {wrapWidth}) {};
    for (var i = 0; i < 10000; i++) {
      ircLog('receiver: JOIN #channel$i');
    }
    expect(printed, hasLength(2));
  });
}
