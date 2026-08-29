import 'resource_api.dart';
import '../models/health_facility.dart';

/// Repository for the `health/facilities` resource (soft-deletes available).
class HealthFacilityRepository {
  final ResourceApi<HealthFacility> api = ResourceApi<HealthFacility>(
    '/health/facilities',
    fromJson: HealthFacility.fromJson,
  );
}
