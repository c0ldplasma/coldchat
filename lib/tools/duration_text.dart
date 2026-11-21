import '../l10n/app_localizations.dart';

/// [duration] in abbreviated units, like "1 s", "10 min", "1 h 30 min" or "14 d", for timeouts.
///
/// - Units are days, hours, minutes and seconds; there are no weeks, so Twitch's longest timeout reads "14 d".
/// - At most two units: the largest one that isn't zero, followed by the next smaller one when that isn't zero
///   ("1 h 30 min", "1 d 2 h", "1 min 30 s"). Anything smaller is left out, so "1 h 0 min 5 s" reads "1 h".
/// - Zero and negative durations read "0 s". A permanent ban has no duration and isn't formatted here.
String shortDuration(Duration duration, AppLocalizations l10n) {
  final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final units = <(int, String Function(int))>[
    (seconds ~/ Duration.secondsPerDay, l10n.durationDaysShort),
    (seconds % Duration.secondsPerDay ~/ Duration.secondsPerHour, l10n.durationHoursShort),
    (seconds % Duration.secondsPerHour ~/ Duration.secondsPerMinute, l10n.durationMinutesShort),
    (seconds % Duration.secondsPerMinute, l10n.durationSecondsShort),
  ];
  final largest = units.indexWhere((unit) => unit.$1 > 0);
  if (largest < 0) return l10n.durationSecondsShort(0);
  final (count, format) = units[largest];
  if (largest + 1 < units.length && units[largest + 1].$1 > 0) {
    final (smallerCount, smallerFormat) = units[largest + 1];
    return l10n.durationPair(format(count), smallerFormat(smallerCount));
  }
  return format(count);
}
