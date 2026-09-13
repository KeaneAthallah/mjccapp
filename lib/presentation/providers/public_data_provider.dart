import 'package:flutter/foundation.dart';

import '../../core/utils/error_messages.dart';
import '../../data/models/public_data_overview.dart';
import '../../data/repositories/public_data_repository.dart';
import '../../data/repositories/repositories.dart';

/// State for the Data Publik hub: loads the sector overview once and keeps it
/// available for category screens.
class PublicDataProvider extends ChangeNotifier {
  PublicDataProvider({PublicDataRepository? repository})
      : _repo = repository ?? Repositories.instance.publicData;

  final PublicDataRepository _repo;

  PublicDataOverview? _overview;
  bool _loading = false;
  String? _error;

  PublicDataOverview? get overview => _overview;
  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => _overview == null && !_loading && _error == null;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _overview = await _repo.overview();
    } catch (e) {
      _error = ErrorMessages.of(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}