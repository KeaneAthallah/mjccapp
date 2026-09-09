import '../../core/network/api_client.dart';
import '../models/map_data.dart';

/// Repository for the map endpoint (`GET /maps`).
class MapRepository {
  Future<MapData> fetch({
    int? kecamatanId,
    String? sector,
    String? type,
  }) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/maps',
      queryParameters: {
        'kecamatan_id': ?kecamatanId,
        if (sector != null && sector.isNotEmpty) 'sector': sector,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    return MapData.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
