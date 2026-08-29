import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/data/models/dashboard_overview.dart';

/// Verifies the exact production `/dashboard` payload parses into the model
/// and every getter the dashboard UI consumes resolves without throwing.
/// Uses the real response snapshot captured from the running Laravel API.
void main() {
  test('real dashboard payload parses and all UI getters resolve', () {
    final file = File('test/fixtures/dashboard_full.json');
    expect(file.existsSync(), isTrue,
        reason: 'fixture missing: run capture script');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    final data = json['data'] as Map<String, dynamic>;
    final overview = DashboardOverview.fromJson(data);

    expect(overview.totalSchools, greaterThanOrEqualTo(0));
    expect(overview.totalStudents, greaterThanOrEqualTo(0));
    expect(overview.totalKecamatan, greaterThanOrEqualTo(0));
    expect(overview.totalKelurahan, greaterThanOrEqualTo(0));
    expect(overview.totalTeachers, greaterThanOrEqualTo(0));
    expect(overview.totalHealthFacilities, greaterThanOrEqualTo(0));
    expect(overview.totalDoctors, greaterThanOrEqualTo(0));
    expect(overview.totalNurses, greaterThanOrEqualTo(0));
    expect(overview.totalMidwives, greaterThanOrEqualTo(0));
    expect(overview.totalMedicalStaff, greaterThanOrEqualTo(0));
    expect(overview.totalTipkamtikmas, greaterThanOrEqualTo(0));
    expect(overview.totalPoskamling, greaterThanOrEqualTo(0));
    expect(overview.totalMarkets, greaterThanOrEqualTo(0));
    expect(overview.totalSecurityAssets, greaterThanOrEqualTo(0));
    expect(overview.population, greaterThanOrEqualTo(0));
    expect(overview.alertsSummary.total, greaterThanOrEqualTo(0));
  });
}
