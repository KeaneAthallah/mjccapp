import 'package:flutter/foundation.dart';

import '../../core/utils/error_messages.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/repositories.dart';

/// State for the profile edit / change password screens.
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profile = Repositories.instance.profile;

  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;

  Future<bool> update({String? email, String? name}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _profile.update(email: email, name: name);
      return true;
    } catch (e) {
      _error = ErrorMessages.of(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _profile.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _error = ErrorMessages.of(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
