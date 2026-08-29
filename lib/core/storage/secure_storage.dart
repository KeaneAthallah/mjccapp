import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] used to persist the bearer
/// token securely (Android Keystore / iOS Keychain).
class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _themeModeKey = 'app_theme_mode';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<void> saveUser(String json) =>
      _storage.write(key: _userKey, value: json);

  static Future<String?> readUser() => _storage.read(key: _userKey);

  static Future<void> saveThemeMode(String mode) =>
      _storage.write(key: _themeModeKey, value: mode);

  static Future<String?> readThemeMode() => _storage.read(key: _themeModeKey);

  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
