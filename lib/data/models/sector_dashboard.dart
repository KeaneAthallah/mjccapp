import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'chart_data.dart';

/// Shared helpers to convert sector dashboard API data into typed models.
class _Helper {
  _Helper._();

  static Map<String, dynamic> map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

  static int stat(Map<String, dynamic> stats, String key) {
    final value = stats[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// `GET /dashboard/education` — pendidikan infographic.
class EducationDashboard {
  const EducationDashboard({
    required this.stats,
    required this.students,
    required this.teacherRatio,
    required this.facilityProgress,
    required this.table,
  });

  final Map<String, dynamic> stats;
  final MultiSeriesChart students;
  final SingleSeriesChart teacherRatio;
  final List<FacilityProgress> facilityProgress;
  final List<dynamic> table;

  int get totalSd => _Helper.stat(stats, 'total_sd');
  int get totalSmp => _Helper.stat(stats, 'total_smp');
  int get totalMaleStudents => _Helper.stat(stats, 'siswa_laki');
  int get totalFemaleStudents => _Helper.stat(stats, 'siswa_perempuan');
  int get totalStudents =>
      totalMaleStudents + totalFemaleStudents;
  int get totalTeachers => _Helper.stat(stats, 'guru');
  int get totalClasses => _Helper.stat(stats, 'kelas');
  int get totalSubjects => _Helper.stat(stats, 'mapel');

  factory EducationDashboard.fromJson(Map<String, dynamic> json) {
    return EducationDashboard(
      stats: _Helper.map(json['statistics']),
      students: MultiSeriesChart.fromJson(
          _Helper.map(json['student_per_kecamatan'])),
      teacherRatio: SingleSeriesChart.fromJson(_Helper.map(json['teacher_ratio'])),
      facilityProgress: (json['facility_progress'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => FacilityProgress.fromJson(_Helper.map(m)))
          .toList(),
      table: json['table'] as List<dynamic>? ?? const [],
    );
  }
}

/// `GET /dashboard/security` — ketertiban infographic.
class SecurityDashboard {
  const SecurityDashboard({
    required this.stats,
    required this.compare,
    required this.distribution,
    required this.kelurahan,
    required this.polseks,
  });

  final Map<String, dynamic> stats;
  final MultiSeriesChart compare;
  final SingleSeriesChart distribution;
  final SingleSeriesChart kelurahan;
  final List<dynamic> polseks;

  int get totalKelurahan => _Helper.stat(stats, 'kelurahan');
  int get totalPolsek => _Helper.stat(stats, 'polsek');
  int get totalTipkamtikmas => _Helper.stat(stats, 'tipkamtikmas');
  int get totalPoskamling => _Helper.stat(stats, 'poskamling');
  int get totalPasar => _Helper.stat(stats, 'pasar');

  factory SecurityDashboard.fromJson(Map<String, dynamic> json) {
    return SecurityDashboard(
      stats: _Helper.map(json['statistics']),
      compare: MultiSeriesChart.fromJson(_Helper.map(json['compare_chart'])),
      distribution:
          SingleSeriesChart.fromJson(_Helper.map(json['poskamling_distribution'])),
      kelurahan: SingleSeriesChart.fromJson(_Helper.map(json['kelurahan_per_kecamatan'])),
      polseks: json['polseks'] as List<dynamic>? ?? const [],
    );
  }
}

/// `GET /dashboard/health` — kesehatan infographic.
class HealthDashboard {
  const HealthDashboard({
    required this.stats,
    required this.workforce,
    required this.proportion,
    required this.capacity,
    required this.table,
  });

  final Map<String, dynamic> stats;
  final MultiSeriesChart workforce;
  final SingleSeriesChart proportion;
  final SingleSeriesChart capacity;
  final List<dynamic> table;

  int get totalPuskesmas => _Helper.stat(stats, 'puskesmas');
  int get totalPustu => _Helper.stat(stats, 'pustu');
  int get totalRs => _Helper.stat(stats, 'rs');
  int get totalPosyandu => _Helper.stat(stats, 'posyandu');
  int get totalDoctors => _Helper.stat(stats, 'dokter');
  int get totalNurses => _Helper.stat(stats, 'perawat');
  int get totalMidwives => _Helper.stat(stats, 'bidan');
  int get totalBeds => _Helper.stat(stats, 'bed');

  factory HealthDashboard.fromJson(Map<String, dynamic> json) {
    return HealthDashboard(
      stats: _Helper.map(json['statistics']),
      workforce: MultiSeriesChart.fromJson(_Helper.map(json['workforce_per_kecamatan'])),
      proportion: SingleSeriesChart.fromJson(_Helper.map(json['facility_proportion'])),
      capacity: SingleSeriesChart.fromJson(_Helper.map(json['capacity_per_kecamatan'])),
      table: json['table'] as List<dynamic>? ?? const [],
    );
  }
}

/// The three sectors with their dashboard endpoints and metadata.
enum SectorKind {
  education(
    title: 'Dashboard Pendidikan',
    subtitle: 'Monitoring sektor pendidikan Kabupaten Morowali',
    icon: Icons.school_outlined,
    color: AppColors.dataPendidikan,
  ),
  security(
    title: 'Dashboard Ketertiban',
    subtitle: 'Monitoring keamanan dan ketertiban Kabupaten Morowali',
    icon: Icons.shield_outlined,
    color: AppColors.dataKeamanan,
  ),
  health(
    title: 'Dashboard Kesehatan',
    subtitle: 'Monitoring fasilitas dan tenaga kesehatan Kabupaten Morowali',
    icon: Icons.local_hospital_outlined,
    color: AppColors.dataKesehatan,
  );

  const SectorKind({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}