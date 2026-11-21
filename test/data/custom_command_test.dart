import 'package:coldchat/data/custom_command.dart';
import 'package:flutter_test/flutter_test.dart';

String _expand(String command, String input) => CustomCommand(trigger: '!so', command: command).expand(input);

void main() {
  group('CustomCommand.expand', () {
    test('without placeholders sends the command as it is', () {
      expect(_expand('Follow them!', '!so ronni'), 'Follow them!');
    });

    test('{N} is word N after the trigger', () {
      expect(_expand('Go follow {1} and {2}', '!so ronni pokimane'), 'Go follow ronni and pokimane');
      expect(_expand('{1}{1}', '!so a'), 'aa');
    });

    test('{N} is empty for 0, no number or past the last word', () {
      expect(_expand('[{0}]', '!so ronni'), '[]');
      expect(_expand('[{}]', '!so ronni'), '[]');
      expect(_expand('[{2}]', '!so ronni'), '[]');
      expect(_expand('[{1}]', '!so'), '[]');
    });

    test('{N+} is word N to the end, joined by spaces', () {
      expect(_expand('Watch {1+}', '!so ronni and friends'), 'Watch ronni and friends');
      expect(_expand('{2+}', '!so ronni and friends'), 'and friends');
      expect(_expand('{3+}', '!so ronni and friends'), 'friends');
    });

    test('{N+} is empty for 0, no number or past the last word', () {
      expect(_expand('[{0+}]', '!so ronni'), '[]');
      expect(_expand('[{+}]', '!so ronni'), '[]');
      expect(_expand('[{2+}]', '!so ronni'), '[]');
    });

    test('splits the trimmed input at single spaces, so repeated spaces make empty words', () {
      expect(_expand('[{1}|{2}]', '  !so ronni  '), '[ronni|]');
      expect(_expand('[{1}|{2}]', '!so  ronni'), '[|ronni]');
      expect(_expand('[{1+}]', '!so  ronni'), '[ ronni]');
    });

    test('keeps line breaks inside a word', () {
      expect(_expand('{1}', '!so a\nb c'), 'a\nb');
    });

    test('expands a {N+} that a {N} word put into the text', () {
      expect(_expand('{1}', '!so {1+} x'), '{1+} x');
    });
  });
}
