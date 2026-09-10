import '../../core/network/api_client.dart';
import '../../core/network/paginated.dart';
import '../models/health_facility.dart';
import '../models/kelurahan.dart';
import '../models/market.dart';
import '../models/polsek.dart';
import '../models/poskamling.dart';
import '../models/public_data_overview.dart';
import '../models/school.dart';
import '../models/tipkamtikmas.dart';
import 'resource_api.dart';

/// Read-only access to the public Data Publik endpoints (`/public/*`).
///
/// Lists reuse the shared [ResourceApi] envelope, so the existing entity
/// models (`School`, `HealthFacility`, …) parse without changes.
class PublicDataRepository {
  final ResourceApi<School> schools = ResourceApi<School>(
    '/public/schools',
    fromJson: School.fromJson,
  );
  final ResourceApi<HealthFacility> healthFacilities = ResourceApi<HealthFacility>(
    '/public/health-facilities',
    fromJson: HealthFacility.fromJson,
  );
  final ResourceApi<Polsek> polseks = ResourceApi<Polsek>(
    '/public/polseks',
    fromJson: Polsek.fromJson,
  );
  final ResourceApi<Poskamling> poskamlings = ResourceApi<Poskamling>(
    '/public/poskamlings',
    fromJson: Poskamling.fromJson,
  );
  final ResourceApi<Tipkamtikmas> tipkamtikmas = ResourceApi<Tipkamtikmas>(
    '/public/tipkamtikmas',
    fromJson: Tipkamtikmas.fromJson,
  );
  final ResourceApi<Market> markets = ResourceApi<Market>(
    '/public/markets',
    fromJson: Market.fromJson,
  );
  final ResourceApi<Kelurahan> kelurahans = ResourceApi<Kelurahan>(
    '/public/kelurahans',
    fromJson: Kelurahan.fromJson,
  );

  Future<PublicDataOverview> overview() async {
    final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/public/overview',
    );
    return PublicDataOverview.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  /// Convenience list helper preserving the [ResourceApi] signature.
  Future<Paginated<T>> index<T>({
    required ResourceApi<T> api,
    int? page,
    int? perPage,
    String? search,
    Map<String, dynamic>? filters,
    String? sort,
    String? sortDirection,
  }) {
    return api.index(
      page: page,
      perPage: perPage,
      search: search,
      filters: filters,
      sort: sort,
      sortDirection: sortDirection,
    );
  }
}