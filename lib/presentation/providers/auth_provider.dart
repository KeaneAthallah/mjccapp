import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_messages.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repositories.dart';

/// Authentication state (login, logout, session restore).
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? auth}) : _auth = auth ?? Repositories.instance.auth {
    ApiClient.instance.onUnauthorized = _handleUnauthorized;
  }

  final AuthRepository _auth;

  UserModel? _user;
  bool _initializing = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _fieldErrors;
  String? _verificationEmail;

  UserModel? get user => _user;
  bool get initializing => _initializing;
  bool get busy => _busy;
  String? get error => _error;
  Map<String, dynamic>? get fieldErrors => _fieldErrors;
  bool get isAuthenticated => _user != null;

  /// Email that needs email verification, set when a login is rejected with
  /// `verification_required`. Cleared on the next successful login attempt.
  String? get verificationEmail => _verificationEmail;
  bool get requiresVerification => _verificationEmail != null;

  UserRole get role => _user?.role ?? UserRole.viewer;
  bool get canWrite => role.canWrite;
  bool get isAdmin => role.isAdmin;

  /// Restores a persisted session at app startup.
  Future<void> restoreSession() async {
    _initializing = true;
    notifyListeners();
    _user = await _auth.storedUser();
    _initializing = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _busy = true;
    _error = null;
    _fieldErrors = null;
    _verificationEmail = null;
    notifyListeners();
    try {
      _user = await _auth.login(email, password);
      return true;
    } on EmailNotVerifiedException catch (e) {
      _verificationEmail = email;
      _error = ErrorMessages.of(e);
      return false;
    } on AppException catch (e) {
      _error = ErrorMessages.of(e);
      _fieldErrors = e.errors;
      return false;
    } catch (e) {
      _error = ErrorMessages.of(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _busy = true;
    _verificationEmail = null;
    notifyListeners();
    await _auth.logout();
    _user = null;
    _busy = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _user = await _auth.me();
      notifyListeners();
    } catch (_) {
      // Keep the stored user if the network call fails.
    }
  }

  void _handleUnauthorized() {
    _user = null;
    _verificationEmail = null;
    notifyListeners();
  }
}
