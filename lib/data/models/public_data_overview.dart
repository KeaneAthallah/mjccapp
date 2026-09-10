/// Statistics returned by the public Data Publik `overview` endpoint.
///
/// Groups the sector counts the way the redesigned Data hub presents them:
/// Pendidikan, Kesehatan, Ketertiban and Fasilitas Publik.
class PublicDataOverview {
  const PublicDataOverview({
    required this.pendidikan,
    required this.kesehatan,
    required this.ketertiban,
    required this.fasilitas,
  });

  final PendidikanStats pendidikan;
  final KesehatanStats kesehatan;
  final KetertibanStats ketertiban;
  final FasilitasStats fasilitas;

  /// Total number of records across all four sectors (for the hub header).
  int get totalRecords =>
      pendidikan.sekolah +
      kesehatan.faskes +
      ketertiban.total +
      fasilitas.pasar;

  factory PublicDataOverview.fromJson(Map<String, dynamic> json) {
    return PublicDataOverview(
      pendidikan: PendidikanStats.fromJson(_map(json['pendidikan'])),
      kesehatan: KesehatanStats.fromJson(_map(json['kesehatan'])),
      ketertiban: KetertibanStats.fromJson(_map(json['ketertiban'])),
      fasilitas: FasilitasStats.fromJson(_map(json['fasilitas'])),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) return const {};
    return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
  }
}

class PendidikanStats {
  const PendidikanStats({
    this.sekolah = 0,
    this.siswa = 0,
    this.guru = 0,
    this.sd = 0,
    this.smp = 0,
  });

  final int sekolah;
  final int siswa;
  final int guru;
  final int sd;
  final int smp;

  factory PendidikanStats.fromJson(Map<String, dynamic> json) {
    return PendidikanStats(
      sekolah: _int(json['sekolah']),
      siswa: _int(json['siswa']),
      guru: _int(json['guru']),
      sd: _int(json['sd']),
      smp: _int(json['smp']),
    );
  }
}

class KesehatanStats {
  const KesehatanStats({
    this.faskes = 0,
    this.puskesmas = 0,
    this.pustu = 0,
    this.rs = 0,
    this.posyandu = 0,
    this.dokter = 0,
    this.perawat = 0,
    this.bidan = 0,
  });

  final int faskes;
  final int puskesmas;
  final int pustu;
  final int rs;
  final int posyandu;
  final int dokter;
  final int perawat;
  final int bidan;

  int get tenagaMedis => dokter + perawat + bidan;

  factory KesehatanStats.fromJson(Map<String, dynamic> json) {
    return KesehatanStats(
      faskes: _int(json['faskes']),
      puskesmas: _int(json['puskesmas']),
      pustu: _int(json['pustu']),
      rs: _int(json['rs']),
      posyandu: _int(json['posyandu']),
      dokter: _int(json['dokter']),
      perawat: _int(json['perawat']),
      bidan: _int(json['bidan']),
    );
  }
}

class KetertibanStats {
  const KetertibanStats({
    this.polsek = 0,
    this.poskamling = 0,
    this.poskamlingAktif = 0,
    this.tipkamtikmas = 0,
  });

  final int polsek;
  final int poskamling;
  final int poskamlingAktif;
  final int tipkamtikmas;

  int get total => polsek + poskamling + tipkamtikmas;

  factory KetertibanStats.fromJson(Map<String, dynamic> json) {
    return KetertibanStats(
      polsek: _int(json['polsek']),
      poskamling: _int(json['poskamling']),
      poskamlingAktif: _int(json['poskamling_aktif']),
      tipkamtikmas: _int(json['tipkamtikmas']),
    );
  }
}

class FasilitasStats {
  const FasilitasStats({
    this.pasar = 0,
    this.kecamatan = 0,
    this.kelurahan = 0,
    this.penduduk = 0,
  });

  final int pasar;
  final int kecamatan;
  final int kelurahan;
  final int penduduk;

  factory FasilitasStats.fromJson(Map<String, dynamic> json) {
    return FasilitasStats(
      pasar: _int(json['pasar']),
      kecamatan: _int(json['kecamatan']),
      kelurahan: _int(json['kelurahan']),
      penduduk: _int(json['penduduk']),
    );
  }
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}