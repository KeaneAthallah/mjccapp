import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/error_messages.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repositories.dart';

/// State for the public self-registration form.
class RegisterProvider extends ChangeNotifier {
  RegisterProvider({AuthRepository? auth})
      : _auth = auth ?? Repositories.instance.auth;

  final AuthRepository _auth;

  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _fieldErrors;

  bool get busy => _busy;
  String? get error => _error;
  Map<String, dynamic>? get fieldErrors => _fieldErrors;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _busy = true;
    _error = null;
    _fieldErrors = null;
    notifyListeners();
    try {
      await _auth.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return true;
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
}