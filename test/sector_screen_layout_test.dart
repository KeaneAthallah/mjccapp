import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mjcc/core/theme/app_theme.dart';
import 'package:mjcc/data/models/sector_dashboard.dart';
import 'package:mjcc/data/models/kecamatan.dart';
import 'package:mjcc/presentation/providers/master_data_provider.dart';
import 'package:mjcc/presentation/providers/sector_dashboard_provider.dart';
import 'package:mjcc/presentation/screens/sector/sector_dashboard_screen.dart';

class _FakeMasterProvider extends MasterDataProvider {
  @override
  List<Kecamatan>? get kecamatans => _kecamatans();
}

List<Kecamatan> _kecamatans() => [
      for (var i = 1; i <= 14; i++) Kecamatan(id: i, name: 'Kecamatan $i'),
    ];

/// Sector provider that serves preset models without any network calls.
class _FakeSectorProvider extends SectorDashboardProvider {
  _FakeSectorProvider(this.model);

  final EducationDashboard model;

  @override
  dynamic modelFor(SectorKind kind) =>
      kind == SectorKind.education ? model : null;

  @override
  bool get loading => false;

  @override
  String? get error => null;

  @override
  Future<void> load(SectorKind kind, {bool silent = false}) async {}

  @override
  Future<void> refresh() async {}
}

EducationDashboard _educationModel() => EducationDashboard.fromJson(const {
      'statistics': {
        'total_sd': '231',
        'total_smp': '92',
        'siswa_laki': '19000',
        'siswa_perempuan': '18300',
        'guru': '2400',
        'kelas': '1500',
        'mapel': '786',
      },
      'student_per_kecamatan': {
        'labels': [
          'Bungku',
          'Bahodopi',
          'Bungku Barat',
          'Bungku Selatan',
          'Bungku Tengah',
          'Bungku Utara',
          'Menui Kepulauan',
          'Mori Atas',
          'Mori Utara',
          'Petasia',
          'Petasia Barat',
          'Petasia Timur',
          'Soyo Jaya',
          'Wita Ponda',
        ],
        'datasets': [
          {
            'label': 'Laki-laki',
            'data': [4000, 3500, 2900, 2400, 2200, 1900, 3800, 4100, 3300, 3000, 2400, 2100, 1600, 1500],
          },
          {
            'label': 'Perempuan',
            'data': [3800, 3400, 2800, 2350, 2150, 1850, 3700, 4000, 3200, 2950, 2350, 2050, 1550, 1450],
          },
        ],
      },
      'teacher_ratio': {
        'labels': [
          'Bungku',
          'Bahodopi',
          'Bungku Barat',
          'Bungku Selatan',
          'Bungku Tengah',
          'Bungku Utara',
          'Menui Kepulauan',
          'Mori Atas',
          'Mori Utara',
          'Petasia',
          'Petasia Barat',
          'Petasia Timur',
          'Soyo Jaya',
          'Wita Ponda',
        ],
        'data': [50, 45, 40, 38, 35, 45, 48, 52, 44, 42, 39, 36, 41, 46],
      },
      'facility_progress': [
        {'name': 'Sarana Utama', 'pct': 85},
        {'name': 'Perpustakaan', 'pct': 72},
        {'name': 'Laboratorium', 'pct': 55},
        {'name': 'Ruang Kelas', 'pct': 91},
        {'name': 'Sanitasi', 'pct': 78},
        {'name': 'Listrik', 'pct': 96},
      ],
      'table': [
        {'name': 'Bungku', 'sd_count': 60, 'smp_count': 25, 'kelas': 300},
        {'name': 'Bahodopi', 'sd_count': 55, 'smp_count': 22, 'kelas': 280},
        {'name': 'Bungku Barat', 'sd_count': 41, 'smp_count': 15, 'kelas': 200},
        {'name': 'Bungku Selatan', 'sd_count': 38, 'smp_count': 12, 'kelas': 185},
        {'name': 'Bungku Tengah', 'sd_count': 35, 'smp_count': 10, 'kelas': 170},
        {'name': 'Bungku Utara', 'sd_count': 30, 'smp_count': 9, 'kelas': 155},
        {'name': 'Menui Kepulauan', 'sd_count': 58, 'smp_count': 20, 'kelas': 275},
        {'name': 'Mori Atas', 'sd_count': 64, 'smp_count': 24, 'kelas': 310},
        {'name': 'Mori Utara', 'sd_count': 50, 'smp_count': 18, 'kelas': 240},
        {'name': 'Petasia', 'sd_count': 48, 'smp_count': 16, 'kelas': 230},
        {'name': 'Petasia Barat', 'sd_count': 37, 'smp_count': 11, 'kelas': 165},
        {'name': 'Petasia Timur', 'sd_count': 33, 'smp_count': 10, 'kelas': 150},
        {'name': 'Soyo Jaya', 'sd_count': 26, 'smp_count': 8, 'kelas': 120},
        {'name': 'Wita Ponda', 'sd_count': 24, 'smp_count': 7, 'kelas': 110},
      ],
    });

Future<void> _pumpSector(
  WidgetTester tester, {
  double textScale = 1.0,
  Size size = const Size(360, 800),
  ThemeData? theme,
  bool withDropdown = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<MasterDataProvider>.value(
      value: withDropdown ? _FakeMasterProvider() : MasterDataProvider(),
      child: ChangeNotifierProvider<SectorDashboardProvider>.value(
        value: _FakeSectorProvider(_educationModel()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme ?? AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const SectorDashboardScreen(kind: SectorKind.education),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.0, 1.3, 1.6]) {
    testWidgets('education screen lays out without overflow at $scale', (
      tester,
    ) async {
      await _pumpSector(tester, textScale: scale);

      expect(tester.takeException(), isNull);
      expect(find.text('DASHBOARD PEMANTAUAN'), findsOneWidget);
      expect(find.byType(SectorDashboardScreen), findsOneWidget);
    });
  }

  testWidgets('dark mode with dropdown renders clean on 320dp', (tester) async {
    await _pumpSector(
      tester,
      textScale: 1.3,
      size: const Size(320, 700),
      theme: AppTheme.dark,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Kecamatan'), findsOneWidget);
  });

  testWidgets('header texts sit inside the header card (not too far top)', (
    tester,
  ) async {
    await _pumpSector(tester);

    final card = tester.getRect(find.byType(SectorDashboardScreen));
    final subtitleTop = tester.getTopLeft(
      find.textContaining('MONITORING SEKTOR PENDIDIKAN'),
    );
    final subtitleBottom = tester.getBottomLeft(
      find.textContaining('MONITORING SEKTOR PENDIDIKAN'),
    );
    final bannerTop = tester.getTopLeft(find.text('DASHBOARD PEMANTAUAN'));

    expect(subtitleTop.dy, greaterThanOrEqualTo(card.top + 16));
    expect(subtitleBottom.dy, lessThan(300));
    expect(subtitleBottom.dy, lessThanOrEqualTo(bannerTop.dy + 1));
  });
}