import '../../core/network/api_client.dart';
import '../models/kecamatan.dart';
import '../models/kelurahan.dart';

/// Repository for the `kecamatans` resource (admin-only writes).
class KecamatanRepository {
  Future<List<Kecamatan>> all() async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/kecamatans',
      queryParameters: {'per_page': 100},
    );
    final body = response.data!;
    final items = body['data'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Kecamatan.fromJson)
        .toList();
  }

  /// Kelurahan that belong to a kecamatan (`GET /kecamatans/{id}/kelurahans`).
  Future<List<Kelurahan>> kelurahans(int kecamatanId) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/kecamatans/$kecamatanId/kelurahans',
    );
    final data = response.data!['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Kelurahan.fromJson)
          .toList();
    }
    return const [];
  }
}
