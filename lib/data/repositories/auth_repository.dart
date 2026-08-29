import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Authentication repository: login, logout and current user.
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
