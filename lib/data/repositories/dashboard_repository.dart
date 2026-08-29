import '../../core/network/api_client.dart';
import '../models/dashboard_overview.dart';

/// Repository for the dashboard endpoints (`GET /dashboard[...]`).
class DashboardRepository {
  Future<DashboardOverview> overview({int? kecamatanId}) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/dashboard',
      queryParameters: {if (kecamatanId != null) 'kecamatan_id': kecamatanId},
    );
    return DashboardOverview.fromJson(ApiClient.envelopeData(response));
  }

  Future<Map<String, dynamic>> education({int? kecamatanId}) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/dashboard/education',
      queryParameters: {if (kecamatanId != null) 'kecamatan_id': kecamatanId},
    );
    return (response.data!['data'] as Map<String, dynamic>?) ?? const {};
  }

  Future<Map<String, dynamic>> security({int? kecamatanId}) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/dashboard/security',
      queryParameters: {if (kecamatanId != null) 'kecamatan_id': kecamatanId},
    );
    return (response.data!['data'] as Map<String, dynamic>?) ?? const {};
  }

  Future<Map<String, dynamic>> health({int? kecamatanId}) async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/dashboard/health',
      queryParameters: {if (kecamatanId != null) 'kecamatan_id': kecamatanId},
    );
    return (response.data!['data'] as Map<String, dynamic>?) ?? const {};
  }
}
