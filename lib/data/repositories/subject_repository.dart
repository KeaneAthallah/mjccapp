import '../../core/network/api_client.dart';
import '../models/subject.dart';

/// Repository for the `subjects` resource (no soft deletes).
class SubjectRepository {
  Future<List<Subject>> all() async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/subjects',
      queryParameters: {'per_page': 100},
    );
    final body = response.data!;
    final items = body['data'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Subject.fromJson)
        .toList();
  }
}
