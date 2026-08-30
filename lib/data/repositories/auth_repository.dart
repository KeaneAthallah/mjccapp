import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Authentication repository: login, logout, current user, public
/// self-registration and email verification.
class AuthRepository {
  Future<UserModel> login(String email, String password) async {
    final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/login',
      data: {'email': email, 'password': password},
    );
    final body = response.data!;
    final data = body['data'] as Map<String, dynamic>? ?? const {};

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AppException('Login gagal. Respons server tidak valid.');
    }

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await SecureStorage.saveToken(token);
    await SecureStorage.saveUser(jsonEncode(user.toJson()));

    return user;
  }

  /// Creates a new `viewer` account. The backend decides the role and sends a
  /// verification email; no token is issued here.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  /// Submits the six-digit code for the given email.
  Future<void> verifyEmail({required String email, required String code}) async {
    await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/email/verify',
      data: {'email': email, 'code': code},
    );
  }

  /// Requests a new verification code for the given email.
  Future<void> resendVerification({required String email}) async {
    await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/email/verification/resend',
      data: {'email': email},
    );
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.dio.post('/logout');
    } on DioException {
      // Best-effort: still clear local credentials even if the server call
      // fails (e.g. offline).
    } finally {
      await SecureStorage.clearAll();
    }
  }

  Future<UserModel> me() async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/me',
    );
    final body = response.data!;
    return UserModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Loads a previously persisted user (no network call).
  Future<UserModel?> storedUser() async {
    final raw = await SecureStorage.readUser();
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      await SecureStorage.clearAll();
      return null;
    }
  }

  /// Whether a bearer token is present locally.
  Future<bool> hasToken() async {
    final token = await SecureStorage.readToken();
    return token != null && token.isNotEmpty;
  }
}
