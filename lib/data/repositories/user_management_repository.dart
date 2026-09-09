import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';
import '../models/user_model.dart';

/// Admin-only repository for the `users` resource.
class UserManagementRepository {
  Future<Paginated<UserModel>> index({
    int? page,
    String? search,
    String? role,
  }) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/users',
      queryParameters: {
        'page': ?page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null && role.isNotEmpty) 'role': role,
      },
    );
    return Paginated<UserModel>.fromJson(
      response.data!,
      (items) => items
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList(),
    );
  }

  Future<UserModel> create({
    required String name,
    required String email,
    required String role,
    required String password,
    String? responderType,
  }) async {
    final response = await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/users',
      data: {
        'name': name,
        'email': email,
        'role': role,
        'responder_type': responderType,
        'password': password,
        'password_confirmation': password,
      },
    );
    return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<UserModel> update(
    int id, {
    String? name,
    String? email,
    String? role,
    String? password,
    String? responderType,
  }) async {
    final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
      '/users/$id',
      data: {
        'name': ?name,
        'email': ?email,
        'role': ?role,
        'responder_type': responderType,
        if (password != null && password.isNotEmpty) 'password': password,
        if (password != null && password.isNotEmpty)
          'password_confirmation': password,
      },
    );
    return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<UserModel> verifyEmail(int id, {bool verified = true}) async {
    final response =
        await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/users/$id/verify-email',
      data: {'verified': verified},
    );
    return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> destroy(int id) async {
    await ApiClient.instance.dio.delete('/users/$id');
  }
}
