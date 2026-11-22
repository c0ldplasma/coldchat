import 'package:intl/intl.dart';

/// [bytes] as a number of megabytes (1 MB = 1,000,000 bytes, like iOS and Android show storage) in [locale]'s number
/// format, for "{size} MB": one decimal below 10 MB, so a small cache doesn't read as "0", whole numbers above.
String megabytes(int bytes, String locale) {
  final value = bytes / 1000000;
  final format = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = value < 10 ? 1 : 0;
  return format.format(value);
}
