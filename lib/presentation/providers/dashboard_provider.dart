import 'package:flutter/foundation.dart';

import '../../core/utils/error_messages.dart';
import '../../data/models/dashboard_overview.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/repositories.dart';

/// State for the main dashboard overview.
class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repo = Repositories.instance.dashboard;

  DashboardOverview? _overview;
  bool _loading = false;
  String? _error;
  int? _kecamatanId;

  DashboardOverview? get overview => _overview;
  bool get loading => _loading;
  String? get error => _error;
  int? get kecamatanId => _kecamatanId;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _overview = await _repo.overview(kecamatanId: _kecamatanId);
    } catch (e, stack) {
      // Keep the technical detail visible during development, then surface a
      // friendly, user-safe message to the UI.
      debugPrint('[Dashboard] load failed: ${e.runtimeType}: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack, label: '[Dashboard] stack');
      }
      _error = ErrorMessages.of(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectKecamatan(int? id) {
    if (_kecamatanId == id) return;
    _kecamatanId = id;
    load();
  }
}
