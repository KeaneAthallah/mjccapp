import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repositories.dart';

/// State for the email verification screen.
///
/// The 60-second resend countdown is a client-side convenience only; the
/// backend enforces its own cooldown and rate limits as the source of truth.
class EmailVerificationProvider extends ChangeNotifier {
  EmailVerificationProvider({required this.email, AuthRepository? auth})
      : _auth = auth ?? Repositories.instance.auth {
    _masked = Formatters.maskEmail(email);
    _startCountdown();
  }

  static const int _cooldownSeconds = 60;

  final AuthRepository _auth;

  /// The email address being verified (lowercased by the input form).
  final String email;

  late final String _masked;

  Timer? _timer;
  bool _verifying = false;
  bool _resending = false;
  bool _success = false;
  int _resendCountdown = 0;
  String? _error;
  Map<String, dynamic>? _fieldErrors;

  String get maskedEmail => _masked;
  bool get verifying => _verifying;
  bool get resending => _resending;
  bool get busy => _verifying || _resending;
  bool get success => _success;
  int get resendCountdown => _resendCountdown;
  bool get canResend => _resendCountdown <= 0 && !_resending;
  String? get error => _error;
  Map<String, dynamic>? get fieldErrors => _fieldErrors;

  Future<bool> verify(String code) async {
    _verifying = true;
    _error = null;
    _fieldErrors = null;
    notifyListeners();
    try {
      await _auth.verifyEmail(email: email, code: code);
      _success = true;
      return true;
    } on AppException catch (e) {
      _error = ErrorMessages.of(e);
      _fieldErrors = e.errors;
      return false;
    } catch (e) {
      _error = ErrorMessages.of(e);
      return false;
    } finally {
      _verifying = false;
      notifyListeners();
    }
  }

  Future<bool> resend() async {
    if (!canResend) return false;
    _resending = true;
    _error = null;
    _fieldErrors = null;
    notifyListeners();
    try {
      await _auth.resendVerification(email: email);
      _startCountdown();
      return true;
    } on AppException catch (e) {
      _error = ErrorMessages.of(e);
      _fieldErrors = e.errors;
      return false;
    } catch (e) {
      _error = ErrorMessages.of(e);
      return false;
    } finally {
      _resending = false;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _resendCountdown = _cooldownSeconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _resendCountdown -= 1;
      notifyListeners();
      if (_resendCountdown <= 0) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}