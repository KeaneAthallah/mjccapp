import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Future<Paginated<AppNotification>> index({int? page, int? perPage}) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {
        'page': ?page,
        'per_page': ?perPage,
      },
    );
    return Paginated<AppNotification>.fromJson(
      response.data!,
      (items) => items
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(),
    );
  }

  Future<void> markRead(int id) async {
    await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/notifications/$id/read',
    );
  }
}
