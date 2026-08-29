import 'resource_api.dart';
import '../models/polsek.dart';

/// Repository for the `polseks` resource (no soft deletes).
class PolsekRepository {
  final ResourceApi<Polsek> api = ResourceApi<Polsek>(
    '/polseks',
    fromJson: Polsek.fromJson,
  );
}
