import '../../core/network/paginated.dart';
import '../../data/models/health_facility.dart';
import '../../data/models/kelurahan.dart';
import '../../data/models/market.dart';
import '../../data/models/polsek.dart';
import '../../data/models/poskamling.dart';
import '../../data/models/school.dart';
import '../../data/models/tipkamtikmas.dart';
import '../../data/repositories/repositories.dart';
import 'list_provider.dart';

/// List state bound to the public Data Publik endpoints (no token required).
abstract class PublicListProvider<T> extends ListProvider<T> {
  PublicListProvider(super.api);

  String get defaultSort => 'name';
}

/// Public list for schools (Pendidikan).
class PublicSchoolListProvider extends PublicListProvider<School> {
  PublicSchoolListProvider() : super(Repositories.instance.publicData.schools);

  @override
  Future<Paginated<School>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// Public list for health facilities (Kesehatan).
class PublicHealthListProvider extends PublicListProvider<HealthFacility> {
  PublicHealthListProvider()
    : super(Repositories.instance.publicData.healthFacilities);

  @override
  Future<Paginated<HealthFacility>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// Public list for polsek (Ketertiban).
class PublicPolsekListProvider extends PublicListProvider<Polsek> {
  PublicPolsekListProvider() : super(Repositories.instance.publicData.polseks);

  @override
  Future<Paginated<Polsek>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// Public list for poskamling (Ketertiban).
class PublicPoskamlingListProvider extends PublicListProvider<Poskamling> {
  PublicPoskamlingListProvider()
    : super(Repositories.instance.publicData.poskamlings);

  @override
  Future<Paginated<Poskamling>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// Public list for tipkamtikmas (Ketertiban).
class PublicTipkamtikmasListProvider extends PublicListProvider<Tipkamtikmas> {
  PublicTipkamtikmasListProvider()
    : super(Repositories.instance.publicData.tipkamtikmas);

  @override
  Future<Paginated<Tipkamtikmas>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// Public list for markets (Fasilitas Publik).
class PublicMarketListProvider extends PublicListProvider<Market> {
  PublicMarketListProvider() : super(Repositories.instance.publicData.markets);

  @override
  Future<Paginated<Market>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}

/// Public list for kelurahans (Fasilitas Publik).
class PublicKelurahanListProvider extends PublicListProvider<Kelurahan> {
  PublicKelurahanListProvider()
    : super(Repositories.instance.publicData.kelurahans);

  @override
  Future<Paginated<Kelurahan>> fetch({required int page}) =>
      api.index(page: page, search: search, filters: filters, sort: 'name');
}