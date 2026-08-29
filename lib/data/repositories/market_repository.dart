import 'resource_api.dart';
import '../models/market.dart';

/// Repository for the `markets` resource (soft-deletes available).
class MarketRepository {
  final ResourceApi<Market> api = ResourceApi<Market>(
    '/markets',
    fromJson: Market.fromJson,
  );
}
