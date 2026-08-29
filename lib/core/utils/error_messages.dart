import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Utilities to extract user-facing messages and field errors from a thrown
/// [Object].
class ErrorMessages {
  ErrorMessages._();

  /// Returns a safe, user-facing message for any thrown [error].
  static String of(Object error) {
    if (error is AppException) {
      return error.message;
    }
    if (error is DioException) {
      // The API client embeds the typed AppException (e.g. NetworkException)
      // inside the DioException; surface its clear message instead of a raw
      // transport error.
      final inner = error.error;
      if (inner is AppException) {
        return inner.message;
      }
      return _dioMessage(error.type);
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  static String _dioMessage(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown =>
        'Tidak dapat terhubung ke server. '
            'Periksa koneksi Anda dan pastikan server berjalan.',
      _ => 'Terjadi kesalahan. Silakan coba lagi.',
    };
  }

  /// Extracts the first field-level validation error for [field] from an
  /// [AppException.errors] map if present.
  static String? fieldError(Object error, String field) {
    if (error is! AppException || error.errors == null) return null;
    final value = error.errors![field];
    if (value is List && value.isNotEmpty) return value.first.toString();
    return null;
  }
}
