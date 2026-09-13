import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/core/theme/app_colors.dart';
import 'package:mjcc/data/models/chart_data.dart';
import 'package:mjcc/data/models/sector_dashboard.dart';

void main() {
  test('ChartDataset.decodeNumbers tolerates mixed num/string/null entries', () {
    final values = ChartDataset.decodeNumbers([1, '42', null, 3.5]);
    expect(values, [1, 42, 0, 3.5]);
    expect(ChartDataset.decodeNumbers(null), isEmpty);
    expect(ChartDataset.decodeNumbers('nope'), isEmpty);
  });

  test('rgba colors are parsed into Flutter colors', () {
    final dataset =
        ChartDataset.fromJson(const {'label': 'Sekolah', 'data': [2], 'backgroundColor': 'rgba(16,185,129,0.8)'});
    expect(dataset.color, const Color(0xFF10B981));
  });

  test('fallback palette colors are used when backgroundColor is absent', () {
    final dataset = ChartDataset.fromJson(const {'label': 'X', 'data': [2]});
    expect(dataset.color, isNull);
  });

  test('MultiSeriesChart.fromJson parses labels and datasets', () {
    final chart = MultiSeriesChart.fromJson(const {
      'labels': ['A', 'B'],
      'datasets': [
        {'label': 'Sekolah', 'data': ['10', 20]},
        {'label': 'Faskes', 'data': [5, 6]},
      ],
    });
    expect(chart.labels, ['A', 'B']);
    expect(chart.datasets.length, 2);
    expect(chart.datasets[0].data, [10, 20]);
    expect(chart.isEmpty, isFalse);
  });

  test('SingleSeriesChart.fromJson parses labels and data', () {
    final chart = SingleSeriesChart.fromJson(const {
      'labels': ['Puskesmas', 'Pustu'],
      'data': [12, 34],
    });
    expect(chart.isEmpty, isFalse);
    expect(chart.data, [12, 34]);
  });

  test('SectorKind colors match the app palette', () {
    expect(SectorKind.education.color, AppColors.dataPendidikan);
    expect(SectorKind.security.color, AppColors.dataKeamanan);
    expect(SectorKind.health.color, AppColors.dataKesehatan);
  });

  test('EducationDashboard parses the sector API payload', () {
    final model = EducationDashboard.fromJson(const {
      'statistics': {
        'total_sd': '120',
        'total_smp': '45',
        'siswa_laki': '19000',
        'siswa_perempuan': '18300',
        'guru': '2400',
        'kelas': '1500',
        'mapel': 14,
      },
      'student_per_kecamatan': {
        'labels': ['Bungku', 'Bahodopi'],
        'datasets': [
          {'label': 'Laki-laki', 'data': [4000, 3500]},
          {'label': 'Perempuan', 'data': [3800, '3400']},
        ],
      },
      'teacher_ratio': {'labels': ['Bungku', 'Bahodopi'], 'data': [50, 45]},
      'facility_progress': [
        {'name': 'Sarana Utama', 'pct': 85},
      ],
      'table': [
        {'name': 'Bungku', 'sd_count': 60, 'smp_count': 15, 'kelas': 300},
      ],
    });

    expect(model.totalSd, 120);
    expect(model.totalSmp, 45);
    expect(model.totalMaleStudents, 19000);
    expect(model.totalFemaleStudents, 18300);
    expect(model.totalStudents, 37300);
    expect(model.totalClasses, 1500);
    expect(model.totalTeachers, 2400);
    expect(model.totalSubjects, 14);
    expect(model.students.datasets.first.data, [4000, 3500]);
    expect(model.teacherRatio.data, [50, 45]);
    expect(model.facilityProgress.single.pct, 85);
    expect(model.table, hasLength(1));
  });

  test('SecurityDashboard parses the sector API payload', () {
    final model = SecurityDashboard.fromJson(const {
      'statistics': {
        'kelurahan': 120,
        'polsek': '6',
        'tipkamtikmas': '180',
        'poskamling': '235',
        'pasar': 26,
      },
      'compare_chart': {
        'labels': ['Bungku', 'Bahodopi'],
        'datasets': [
          {'label': 'Tipkamtikmas', 'data': [3, 4]},
          {'label': 'Poskamling', 'data': [10, 8]},
        ],
      },
      'poskamling_distribution': {'labels': ['Bungku'], 'data': [40]},
      'kelurahan_per_kecamatan': {'labels': ['Bungku'], 'data': [5]},
      'polseks': [
        {'name': 'Polsek Bungku', 'personnel_count': 12, 'poskamling_count': 9},
      ],
    });

    expect(model.totalKelurahan, 120);
    expect(model.totalPolsek, 6);
    expect(model.totalTipkamtikmas, 180);
    expect(model.totalPoskamling, 235);
    expect(model.totalPasar, 26);
    expect(model.compare.datasets, hasLength(2));
    expect(model.distribution.labels, ['Bungku']);
    expect(model.polseks, hasLength(1));
  });

  test('HealthDashboard parses the sector API payload', () {
    final model = HealthDashboard.fromJson(const {
      'statistics': {
        'puskesmas': '8',
        'pustu': '45',
        'rs': 2,
        'posyandu': '300',
        'dokter': '52',
        'perawat': '250',
        'bidan': '102',
        'bed': '500',
      },
      'workforce_per_kecamatan': {
        'labels': ['Bungku'],
        'datasets': [
          {'label': 'Dokter', 'data': [5]},
          {'label': 'Perawat', 'data': [20]},
          {'label': 'Bidan', 'data': [10]},
        ],
      },
      'facility_proportion': {'labels': ['Puskesmas'], 'data': [8]},
      'capacity_per_kecamatan': {'labels': ['Bungku'], 'data': [120]},
      'table': [
        {'name': 'Bungku', 'puskesmas_count': 2, 'bed': 80},
      ],
    });

    expect(model.totalPuskesmas, 8);
    expect(model.totalPustu, 45);
    expect(model.totalRs, 2);
    expect(model.totalPosyandu, 300);
    expect(model.totalDoctors, 52);
    expect(model.totalNurses, 250);
    expect(model.totalMidwives, 102);
    expect(model.totalBeds, 500);
    expect(model.workforce.datasets, hasLength(3));
    expect(model.proportion.data, [8]);
    expect(model.capacity.data, [120]);
  });
}