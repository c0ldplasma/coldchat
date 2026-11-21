import 'package:flutter/foundation.dart';

/// Writes an `[irc]` diagnostics line for connection state changes, JOINs and reconnects.
///
/// It only goes to [debugPrint], which also prints in release builds, so `adb logcat` and the iOS console show it.
/// Nothing is kept by the app: the system log is a ring buffer. Call it for bounded events only, never per chat
/// line or PING, so a long session can't spam the log.
void ircLog(String message) => debugPrint('[irc] $message');
