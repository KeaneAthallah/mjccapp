import '../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Profile repository for `GET/PUT /profile` and `PUT /profile/password`.
class ProfileRepository {
  Future<UserModel> show() async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/profile',
    );
    return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<String> update({String? email, String? name}) async {
    final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
      '/profile',
      data: {if (email != null) 'email': email, if (name != null) 'name': name},
    );
    return (response.data?['message'] as String?) ??
        'Profil berhasil diperbarui.';
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await ApiClient.instance.dio.put<Map<String, dynamic>>(
      '/profile/password',
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
    return (response.data?['message'] as String?) ??
        'Kata sandi berhasil diperbarui.';
  }
}
