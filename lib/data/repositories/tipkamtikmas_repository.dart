import 'resource_api.dart';
import '../models/tipkamtikmas.dart';

/// Repository for the `tipkamtikmas` resource (soft-deletes available).
///
/// Note: the route parameter on the server is `tipkamtikma` (singular).
class TipkamtikmasRepository {
  final ResourceApi<Tipkamtikmas> api = ResourceApi<Tipkamtikmas>(
    '/tipkamtikmas',
    fromJson: Tipkamtikmas.fromJson,
  );
}
