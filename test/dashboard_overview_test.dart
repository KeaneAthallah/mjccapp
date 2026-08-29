import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/data/models/dashboard_overview.dart';

void main() {
  test('DashboardOverview parses string-valued stats without throwing', () {
    // The API returns some aggregates as strings (e.g. "39500").
    final overview = DashboardOverview.fromJson(const {
      'stats': {
        'total_sekolah': 170,
        'total_siswa': '39500',
        'total_guru': '2395',
        'total_dokter': '52',
        'total_perawat': '250',
        'total_bidan': '102',
        'population': '262269',
        'total_poskamling': 235,
        'total_pasar': 26,
      },
      'alerts': {
        'critical': [],
        'warning': [],
        'info': [],
      },
    });

    expect(overview.totalSchools, 170);
    expect(overview.totalStudents, 39500);
    expect(overview.totalTeachers, 2395);
    expect(overview.totalDoctors, 52);
    expect(overview.totalNurses, 250);
    expect(overview.totalMidwives, 102);
    expect(overview.totalMedicalStaff, 404);
    expect(overview.population, 262269);
    expect(overview.totalSecurityAssets, 261);
  });

  test('DashboardOverview tolerates chart fields returned as maps', () {
    final overview = DashboardOverview.fromJson(const {
      'comparison': {
        'labels': ['A', 'B'],
        'datasets': [],
      },
      'student_chart': {
        'labels': ['A'],
        'datasets': [],
      },
      'health_workforce_chart': {
        'labels': ['A'],
        'data': [1, 2],
      },
      'infra_composition': {
        'labels': ['Sekolah', 'Faskes'],
        'data': [10, 5],
      },
    });

    expect(overview.comparison['labels'], isA<List<dynamic>>());
    expect(overview.studentChart, isNotEmpty);
    expect(overview.healthWorkforceChart['data'], isA<List<dynamic>>());
    expect(overview.infraComposition['labels'], isA<List<dynamic>>());
  });

  test('DashboardOverview tolerates missing and malformed stats', () {
    final overview = DashboardOverview.fromJson(const {'stats': {}});

    expect(overview.totalStudents, 0);
    expect(overview.population, 0);
    expect(overview.alertsSummary.total, 0);
  });
}
