import 'package:coldchat/data/home/start_screen_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a fresh install shows the start screen; a login or continuing hides it', () {
    expect(showsStartScreen(done: false, hasAccount: false), isTrue);
    expect(showsStartScreen(done: false, hasAccount: true), isFalse);
    expect(showsStartScreen(done: true, hasAccount: false), isFalse);
  });

  test('installs from before the start screen with a login or channels skip it', () {
    expect(startScreenAlreadyDone(hasAccount: false, hasChannels: false), isFalse);
    expect(startScreenAlreadyDone(hasAccount: true, hasChannels: false), isTrue);
    expect(startScreenAlreadyDone(hasAccount: false, hasChannels: true), isTrue);
  });

  group('StartScreenCubit', () {
    late bool done;
    late bool hasAccount;
    late ChangeNotifier changes;
    late StartScreenCubit cubit;

    StartScreenCubit create() => StartScreenCubit(
      isDone: () => done,
      markDone: () async {
        done = true;
        changes.notifyListeners();
      },
      hasAccount: () => hasAccount,
      changes: changes,
    );

    setUp(() {
      done = false;
      hasAccount = false;
      changes = ChangeNotifier();
    });

    tearDown(() async {
      await cubit.close();
      changes.dispose();
    });

    test('shows on a fresh install, and continuing without logging in hides it for good', () async {
      cubit = create();
      expect(cubit.state, isTrue);

      await cubit.continueWithoutLogin();
      expect(done, isTrue);
      expect(cubit.state, isFalse);
    });

    test('a login hides it and marks it done, so removing the account later does not bring it back', () async {
      cubit = create();
      hasAccount = true;
      changes.notifyListeners();
      expect(cubit.state, isFalse);
      expect(done, isTrue);

      hasAccount = false;
      changes.notifyListeners();
      expect(cubit.state, isFalse);
    });

    test('with an account from before, it never shows and is marked done', () {
      hasAccount = true;
      cubit = create();
      expect(cubit.state, isFalse);
      expect(done, isTrue);
    });
  });
}
