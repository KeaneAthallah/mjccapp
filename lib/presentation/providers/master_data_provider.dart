import 'package:flutter/foundation.dart';

import '../../core/utils/error_messages.dart';
import '../../data/models/kecamatan.dart';
import '../../data/models/kelurahan.dart';
import '../../data/models/subject.dart';
import '../../data/repositories/repositories.dart';

/// Loads shared reference data (kecamatan, subjects, kelurahan-by-kecamatan)
/// used by list filters and create/edit forms.
class MasterDataProvider extends ChangeNotifier {
  final Repositories _repo = Repositories.instance;

  List<Kecamatan>? _kecamatans;
  List<Subject>? _subjects;
  List<Kelurahan> _kelurahans = [];
  int? _kelurahanKecamatanId;
  bool _loadingKecamatan = false;
  bool _loadingKelurahan = false;
  String? _error;

  List<Kecamatan>? get kecamatans => _kecamatans;
  List<Subject>? get subjects => _subjects;
  List<Kelurahan> get kelurahans => _kelurahans;
  bool get loadingKecamatan => _loadingKecamatan;
  bool get loadingKelurahan => _loadingKelurahan;
  String? get error => _error;

  /// Loads kecamatan + subjects in parallel (once) for pickers.
  Future<void> ensureLoaded() async {
    if (_kecamatans != null && _subjects != null) return;
    _loadingKecamatan = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.kecamatan.all(),
        _repo.subject.all(),
      ]);
      _kecamatans = results[0] as List<Kecamatan>;
      _subjects = results[1] as List<Subject>;
    } catch (e) {
      _error = ErrorMessages.of(e);
    } finally {
      _loadingKecamatan = false;
      notifyListeners();
    }
  }

  /// Loads the kelurahan for the given kecamatan (cached per kecamatan).
  Future<void> loadKelurahan(int kecamatanId) async {
    if (_kelurahanKecamatanId == kecamatanId && _kelurahans.isNotEmpty) return;
    _loadingKelurahan = true;
    _kelurahanKecamatanId = kecamatanId;
    notifyListeners();
    try {
      _kelurahans = await _repo.kecamatan.kelurahans(kecamatanId);
    } catch (e) {
      _kelurahans = [];
      _error = ErrorMessages.of(e);
    } finally {
      _loadingKelurahan = false;
      notifyListeners();
    }
  }

  String kecamatanName(int? id) {
    if (id == null) return '-';
    return _kecamatans
            ?.firstWhere(
              (k) => k.id == id,
              orElse: () => Kecamatan(id: id, name: ''),
            )
            .name ??
        '-';
  }

  String kelurahanName(int? id) {
    if (id == null) return '-';
    return _kelurahans
            .firstWhere((k) => k.id == id, orElse: () => Kelurahan(id: id))
            .name ??
        '-';
  }
}
