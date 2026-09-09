import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';
import '../models/activity_log.dart';

/// Repository for the admin audit log endpoint (`GET /audit`).
class AuditRepository {
  Future<Paginated<ActivityLog>> index({
    int? page,
    String? search,
    int? userId,
    String? action,
    String? resource,
    String? from,
    String? to,
  }) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/audit',
      queryParameters: {
        'page': ?page,
        if (search != null && search.isNotEmpty) 'search': search,
        'user': ?userId,
        if (action != null && action.isNotEmpty) 'action': action,
        if (resource != null && resource.isNotEmpty) 'resource': resource,
        'from': ?from,
        'to': ?to,
      },
    );
    return Paginated<ActivityLog>.fromJson(
      response.data!,
      (items) => items
          .whereType<Map<String, dynamic>>()
          .map(ActivityLog.fromJson)
          .toList(),
    );
  }
}
