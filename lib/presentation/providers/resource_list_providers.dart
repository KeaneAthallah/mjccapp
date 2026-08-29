import '../../core/network/paginated.dart';
import '../../data/models/health_facility.dart';
import '../../data/models/market.dart';
import '../../data/models/polsek.dart';
import '../../data/models/poskamling.dart';
import '../../data/models/school.dart';
import '../../data/models/tipkamtikmas.dart';
import '../../data/repositories/repositories.dart';
import 'list_provider.dart';

/// List state for the schools screen.
class SchoolListProvider extends ListProvider<School> {
  SchoolListProvider() : super(Repositories.instance.school.api);

  @override
  Future<Paginated<School>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// List state for the health facilities screen.
class HealthFacilityListProvider extends ListProvider<HealthFacility> {
  HealthFacilityListProvider()
    : super(Repositories.instance.healthFacility.api);

  @override
  Future<Paginated<HealthFacility>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// List state for the polsek screen.
class PolsekListProvider extends ListProvider<Polsek> {
  PolsekListProvider() : super(Repositories.instance.polsek.api);

  @override
  Future<Paginated<Polsek>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// List state for the market screen.
class MarketListProvider extends ListProvider<Market> {
  MarketListProvider() : super(Repositories.instance.market.api);

  @override
  Future<Paginated<Market>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// List state for the poskamling screen.
class PoskamlingListProvider extends ListProvider<Poskamling> {
  PoskamlingListProvider() : super(Repositories.instance.poskamling.api);

  @override
  Future<Paginated<Poskamling>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// List state for the tipkamtikmas screen.
class TipkamtikmasListProvider extends ListProvider<Tipkamtikmas> {
  TipkamtikmasListProvider() : super(Repositories.instance.tipkamtikmas.api);

  @override
  Future<Paginated<Tipkamtikmas>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}
