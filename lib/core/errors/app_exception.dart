/// A typed application exception that can safely be shown to the user.
class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.errors});

  /// Human-readable, user-safe message.
  final String message;

  /// Optional HTTP status code when the error came from the backend.
  final int? statusCode;

  /// Field-level validation errors, e.g. `{'email': ['...']}` for a 422.
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

/// Raised when the user's session has expired or been revoked (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}

/// Raised when the user lacks permission for an action (HTTP 403).
class ForbiddenException extends AppException {
  const ForbiddenException(super.message);
}

/// Raised when the backend reports that the account's email is not yet
/// verified (HTTP 403 with `verification_required: true`).
class EmailNotVerifiedException extends AppException {
  const EmailNotVerifiedException(super.message);
}

/// Raised when the backend reports a validation failure (HTTP 422).
class ValidationException extends AppException {
  const ValidationException(super.message, {Map<String, dynamic>? errors})
    : super(errors: errors);
}

/// Raised when there is no network connectivity.
class NetworkException extends AppException {
  const NetworkException(super.message);
}
