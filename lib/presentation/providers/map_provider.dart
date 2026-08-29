import 'package:flutter/foundation.dart';

import '../../core/utils/error_messages.dart';
import '../../data/models/map_data.dart';
import '../../data/repositories/map_repository.dart';
import '../../data/repositories/repositories.dart';

/// State for the map screen.
class MapProvider extends ChangeNotifier {
  final MapRepository _repo = Repositories.instance.map;

  MapData? _data;
  bool _loading = false;
  String? _error;
  String _sector = '';
  String _type = '';
  int? _kecamatanId;

  MapData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  String get sector => _sector;
  String get type => _type;
  int? get kecamatanId => _kecamatanId;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _repo.fetch(
        kecamatanId: _kecamatanId,
        sector: _sector,
        type: _type,
      );
    } catch (e) {
      _error = ErrorMessages.of(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSector(String value) {
    if (_sector == value) return;
    _sector = value;
    _type = '';
    load();
  }

  void setType(String value) {
    if (_type == value) return;
    _type = value;
    load();
  }

  void setKecamatan(int? id) {
    if (_kecamatanId == id) return;
    _kecamatanId = id;
    load();
  }
}
