import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// Whether an install counts as past the start screen, without the flag being set: installs from before the start
/// screen existed, which already have a login or opened channels, never see it.
bool startScreenAlreadyDone({required bool hasAccount, required bool hasChannels}) => hasAccount || hasChannels;

/// Whether the full-screen start screen (no tab bar) of a fresh install shows. It goes away for good once the user
/// logs in or continues without logging in.
bool showsStartScreen({required bool done, required bool hasAccount}) => !done && !hasAccount;

/// [showsStartScreen] as state, for the home page. Marks the start screen done as soon as an account is there, so
/// removing that account later leads to the normal home tab, not back to the start screen.
class StartScreenCubit extends Cubit<bool> {
  final bool Function() _isDone;
  final Future<void> Function() _markDone;
  final bool Function() _hasAccount;
  final Listenable _changes;

  /// [changes] fires when [isDone] or [hasAccount] may have changed: whether the start screen was left, or the accounts.
  StartScreenCubit({
    required this._isDone,
    required this._markDone,
    required this._hasAccount,
    required this._changes,
  }) : super(showsStartScreen(done: _isDone(), hasAccount: _hasAccount())) {
    _changes.addListener(_update);
    _update();
  }

  /// "Continue without logging in".
  Future<void> continueWithoutLogin() => _markDone();

  void _update() {
    if (isClosed) return;
    final done = _isDone();
    final hasAccount = _hasAccount();
    if (hasAccount && !done) unawaited(_markDone());
    emit(showsStartScreen(done: done, hasAccount: hasAccount));
  }

  @override
  Future<void> close() {
    _changes.removeListener(_update);
    return super.close();
  }
}
