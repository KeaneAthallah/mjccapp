import 'audit_repository.dart';
import 'auth_repository.dart';
import 'dashboard_repository.dart';
import 'health_facility_repository.dart';
import 'kecamatan_repository.dart';
import 'map_repository.dart';
import 'market_repository.dart';
import 'notification_repository.dart';
import 'polsek_repository.dart';
import 'poskamling_repository.dart';
import 'profile_repository.dart';
import 'public_data_repository.dart';
import 'school_repository.dart';
import 'sos_repository.dart';
import 'subject_repository.dart';
import 'tipkamtikmas_repository.dart';
import 'user_management_repository.dart';

/// Simple service locator container for all repositories.
class Repositories {
  Repositories._();

  static final Repositories instance = Repositories._();

  final AuthRepository auth = AuthRepository();
  final ProfileRepository profile = ProfileRepository();
  final DashboardRepository dashboard = DashboardRepository();
  final MapRepository map = MapRepository();
  final KecamatanRepository kecamatan = KecamatanRepository();
  final SubjectRepository subject = SubjectRepository();
  final SchoolRepository school = SchoolRepository();
  final HealthFacilityRepository healthFacility = HealthFacilityRepository();
  final PolsekRepository polsek = PolsekRepository();
  final MarketRepository market = MarketRepository();
  final PoskamlingRepository poskamling = PoskamlingRepository();
  final TipkamtikmasRepository tipkamtikmas = TipkamtikmasRepository();
  final UserManagementRepository userManagement = UserManagementRepository();
  final AuditRepository audit = AuditRepository();
  final SosRepository sos = SosRepository();
  final NotificationRepository notification = NotificationRepository();
  final PublicDataRepository publicData = PublicDataRepository();
}
