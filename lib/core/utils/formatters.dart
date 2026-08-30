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

  /// Masks an email address for display, e.g. `u***@gmail.com`.
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email.substring(0, 1)}***${email.substring(at)}';
  }
}
