/// Dashboard overview (`GET /dashboard`).
class DashboardOverview {
  const DashboardOverview({
    required this.stats,
    required this.comparison,
    required this.infraComposition,
    required this.studentChart,
    required this.healthWorkforceChart,
    required this.topSchools,
    required this.topPoskamling,
    required this.topHealth,
    required this.perKecamatan,
    required this.alerts,
  });

  final Map<String, dynamic> stats;
  final Map<String, dynamic> comparison;
  final Map<String, dynamic> infraComposition;
  final Map<String, dynamic> studentChart;
  final Map<String, dynamic> healthWorkforceChart;
  final List<dynamic> topSchools;
  final List<dynamic> topPoskamling;
  final List<dynamic> topHealth;
  final List<dynamic> perKecamatan;
  final Map<String, dynamic> alerts;

  int get totalSchools => _statInt('total_sekolah');
  int get totalStudents => _statInt('total_siswa');
  int get totalKecamatan => _statInt('kecamatan');
  int get totalKelurahan => _statInt('kelurahan');
  int get totalTeachers => _statInt('total_guru');
  int get totalHealthFacilities => _statInt('total_faskes');
  int get totalDoctors => _statInt('total_dokter');
  int get totalNurses => _statInt('total_perawat');
  int get totalMidwives => _statInt('total_bidan');
  int get totalMedicalStaff => totalDoctors + totalNurses + totalMidwives;
  int get totalTipkamtikmas => _statInt('total_tipkamtikmas');
  int get totalPoskamling => _statInt('total_poskamling');
  int get totalMarkets => _statInt('total_pasar');
  int get totalSecurityAssets => totalPoskamling + totalMarkets;
  int get population => _statInt('population');

  /// Reads a numeric stat, tolerating values that arrive as a [num] or as a
  /// numeric [String] (the API returns some aggregates as strings).
  int _statInt(String key) {
    final value = stats[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  AlertsSummary get alertsSummary => AlertsSummary.fromJson(alerts);

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      stats: _map(json['stats']),
      comparison: _map(json['comparison']),
      infraComposition: _map(json['infra_composition']),
      studentChart: _map(json['student_chart']),
      healthWorkforceChart: _map(json['health_workforce_chart']),
      topSchools: json['top_schools'] as List<dynamic>? ?? const [],
      topPoskamling: json['top_poskamling'] as List<dynamic>? ?? const [],
      topHealth: json['top_health'] as List<dynamic>? ?? const [],
      perKecamatan: json['per_kecamatan'] as List<dynamic>? ?? const [],
      alerts: _map(json['alerts']),
    );
  }

  /// Tolerantly converts any Map (e.g. `jsonDecode` output or a const literal)
  /// to `Map<String, dynamic>`, falling back to an empty map when absent.
  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) return const {};
    return Map<String, dynamic>.from(value.cast<dynamic, dynamic>());
  }
}

/// Alert section within the dashboard (critical / warning / info).
class AlertsSummary {
  const AlertsSummary({
    required this.critical,
    required this.warning,
    required this.info,
  });

  final List<dynamic> critical;
  final List<dynamic> warning;
  final List<dynamic> info;

  int get total => critical.length + warning.length + info.length;

  factory AlertsSummary.fromJson(Map<String, dynamic> json) {
    List<dynamic> list(Object? value) =>
        value is List ? value : const <dynamic>[];
    return AlertsSummary(
      critical: list(json['critical']),
      warning: list(json['warning']),
      info: list(json['info']),
    );
  }
}
