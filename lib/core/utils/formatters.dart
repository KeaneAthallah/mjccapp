import 'package:intl/intl.dart';

/// Shared formatting helpers.
class Formatters {
  Formatters._();

  static String longDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
  }

  static String shortDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  static String number(int? value) {
    if (value == null) return '-';
    return NumberFormat.decimalPattern('id').format(value);
  }
}
