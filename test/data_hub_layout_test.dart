import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mjcc/core/theme/app_theme.dart';
import 'package:mjcc/data/models/kecamatan.dart';
import 'package:mjcc/data/models/public_data_overview.dart';
import 'package:mjcc/data/repositories/public_data_repository.dart';
import 'package:mjcc/presentation/providers/master_data_provider.dart';
import 'package:mjcc/presentation/providers/public_data_provider.dart';
import 'package:mjcc/presentation/screens/data/data_hub_screen.dart';
import 'package:mjcc/presentation/screens/data/public_data_list_screen.dart';

class _FakeMasterProvider extends MasterDataProvider {
  @override
  List<Kecamatan>? get kecamatans => const [];
}

/// Public-data repository serving a preset overview without any network IO.
class _FakePublicRepo extends PublicDataRepository {
  @override
  Future<PublicDataOverview> overview() async =>
      PublicDataOverview.fromJson(const {
        'pendidikan': {
          'sekolah': 216,
          'siswa': 40258,
          'guru': 3056,
          'sd': 155,
          'smp': 41,
        },
        'kesehatan': {
          'faskes': 11,
          'puskesmas': 11,
          'pustu': 0,
          'rs': 0,
          'posyandu': 0,
          'dokter': 20,
          'perawat': 231,
          'bidan': 415,
        },
        'ketertiban': {
          'polsek': 4,
          'poskamling': 0,
          'poskamling_aktif': 0,
          'tipkamtikmas': 0,
        },
        'fasilitas': {
          'pasar': 1,
          'kecamatan': 10,
          'kelurahan': 46,
          'penduduk': 132996,
        },
      });
}

Future<void> _pumpHub(
  WidgetTester tester, {
  double textScale = 1.0,
  Size size = const Size(360, 800),
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MasterDataProvider>.value(
          value: _FakeMasterProvider(),
        ),
        ChangeNotifierProvider<PublicDataProvider>(
          create: (_) => PublicDataProvider(repository: _FakePublicRepo()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme ?? AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const DataHubScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  for (final scale in [1.0, 1.3, 1.6]) {
    testWidgets('data hub full content renders clean at $scale', (
      tester,
    ) async {
      // Tall viewport so the lazy ListView builds every section.
      await _pumpHub(tester, textScale: scale, size: const Size(360, 2400));

      expect(tester.takeException(), isNull);

      // Real Scaffold now (AppBar present) instead of a floating blank route.
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Data Publik'), findsWidgets);
      // KPI stat cards.
      expect(find.text('SEKOLAH'), findsOneWidget);
      expect(find.text('FASILITAS KESEHATAN'), findsOneWidget);
      // Chart card + legend.
      expect(find.text('Penyebaran Data per Sektor'), findsOneWidget);
      expect(find.text('Pendidikan'), findsNWidgets(2)); // legend + sector card
      expect(find.text('Fasilitas Publik'), findsOneWidget);
    });
  }

  testWidgets('dark mode hub renders without overflow on 320dp', (
    tester,
  ) async {
    await _pumpHub(
      tester,
      textScale: 1.3,
      size: const Size(320, 700),
      theme: AppTheme.dark,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets(
    'opening Pendidikan list shows summary header + charts, never a blank body',
    (tester) async {
      await _pumpHub(tester, size: const Size(360, 2000));

      // Tap the Pendidikan sector card (second match = the card, after the
      // legend label).
      await tester.tap(find.text('Pendidikan').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('Pendidikan'), findsOneWidget);
      expect(find.text('Ringkasan Pendidikan'), findsOneWidget);
      // Search field + summary chart are present even before the list provider
      // resolves (real network is blocked in tests -> error view).
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a hub stat card opens its sector list (Sekolah -> Pendidikan)',
    (tester) async {
      await _pumpHub(tester, size: const Size(360, 2400));

      await tester.tap(find.text('SEKOLAH'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.byType(PublicDataListScreen), findsOneWidget);
      expect(find.text('Ringkasan Pendidikan'), findsOneWidget);
    },
  );

  testWidgets('tapping a chart legend row opens its sector list (Fasilitas)', (
    tester,
  ) async {
    await _pumpHub(tester, size: const Size(360, 2400));

    await tester.tap(find.text('Fasilitas'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.byType(PublicDataListScreen), findsOneWidget);
    expect(find.text('Ringkasan Fasilitas Publik'), findsOneWidget);
  });
}
