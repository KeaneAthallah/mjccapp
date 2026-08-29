import 'resource_api.dart';
import '../models/school.dart';

/// Repository for the `schools` resource (soft-deletes available).
class SchoolRepository {
  final ResourceApi<School> api = ResourceApi<School>(
    '/schools',
    fromJson: School.fromJson,
  );
}
