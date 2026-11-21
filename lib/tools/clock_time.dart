import 'package:flutter/material.dart';

/// The time of day of [time] the way the app's language writes it, like "9:05 PM" in English or "21:05" in German.
/// With [alwaysUse24HourFormat] (the phone's 24-hour setting) it's always a 24-hour clock.
String clockTime(DateTime time, MaterialLocalizations localizations, {bool alwaysUse24HourFormat = false}) =>
    localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time), alwaysUse24HourFormat: alwaysUse24HourFormat);

/// [clockTime] for the language and 24-hour setting of [context], for message timestamps.
String clockTimeOf(BuildContext context, DateTime time) => clockTime(
  time,
  MaterialLocalizations.of(context),
  alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
);
