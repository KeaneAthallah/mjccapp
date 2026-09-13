import 'package:flutter/foundation.dart';

import '../../core/utils/error_messages.dart';
import '../../data/models/sector_dashboard.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/repositories.dart';

/// State for the sector dashboards (`/dashboard/education|security|health`).
/// One instance serves all three sector screens; each screen loads its own
/// kind and reacts to kecamatan filter changes through [selectKecamatan].
class SectorDashboardProvider extends ChangeNotifier {
  final DashboardRepository _repo = Repositories.instance.dashboard;

  SectorKind? _active;
  EducationDashboard? _education;
  SecurityDashboard? _security;
  HealthDashboard? _health;

  bool _loading = false;
  String? _error;
  int? _kecamatanId;

  SectorKind? get active => _active;
  EducationDashboard? get education => _education;
  SecurityDashboard? get security => _security;
  HealthDashboard? get health => _health;
  bool get loading => _loading;
  String? get error => _error;
  int? get kecamatanId => _kecamatanId;

  dynamic modelFor(SectorKind kind) => switch (kind) {
        SectorKind.education => _education,
        SectorKind.security => _security,
        SectorKind.health => _health,
      };

  Future<void> load(SectorKind kind, {bool silent = false}) async {
    if (!silent) {
      _loading = true;
    }
    _error = null;
    _active = kind;
    notifyListeners();
    try {
      switch (kind) {
        case SectorKind.education:
          _education =
              EducationDashboard.fromJson(await _repo.education(kecamatanId: _kecamatanId));
        case SectorKind.security:
          _security =
              SecurityDashboard.fromJson(await _repo.security(kecamatanId: _kecamatanId));
        case SectorKind.health:
          _health =
              HealthDashboard.fromJson(await _repo.health(kecamatanId: _kecamatanId));
      }
    } catch (e, stack) {
      debugPrint('[SectorDashboard] load($kind) failed: ${e.runtimeType}: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack, label: '[SectorDashboard] stack');
      }
      _error = ErrorMessages.of(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_active != null) await load(_active!);
  }

  void selectKecamatan(SectorKind kind, int? id) {
    if (_kecamatanId == id) return;
    _kecamatanId = id;
    load(kind);
  }
}