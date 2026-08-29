import 'resource_api.dart';
import '../models/poskamling.dart';

/// Repository for the `poskamlings` resource (soft-deletes available).
class PoskamlingRepository {
  final ResourceApi<Poskamling> api = ResourceApi<Poskamling>(
    '/poskamlings',
    fromJson: Poskamling.fromJson,
  );
}
