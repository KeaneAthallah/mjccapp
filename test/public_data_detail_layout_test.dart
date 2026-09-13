import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/core/theme/app_theme.dart';
import 'package:mjcc/data/models/health_facility.dart';
import 'package:mjcc/data/models/kelurahan.dart';
import 'package:mjcc/data/models/market.dart';
import 'package:mjcc/data/models/polsek.dart';
import 'package:mjcc/data/models/poskamling.dart';
import 'package:mjcc/data/models/school.dart';
import 'package:mjcc/data/models/subject.dart';
import 'package:mjcc/data/models/tipkamtikmas.dart';
import 'package:mjcc/presentation/screens/data/public_data_detail_screen.dart';
import 'package:mjcc/presentation/screens/data/public_data_entity.dart';

typedef _Loader = Future<Object> Function(PublicDataEntity entity, int id);

_Loader _sample(PublicDataEntity entity) {
  return (e, id) async {
    return switch (entity) {
      PublicDataEntity.school => const School(
          id: 1,
          name: 'SMPN 1 Morowali Utara - Bungku Utara',
          npsn: '12345678',
          schoolType: 'SMP',
          kecamatan: 'Bungku Utara',
          kelurahan: 'Taronggo',
          address: 'Jl. Poros Morowali Utara No. 1',
          latitude: -2.5412,
          longitude: 121.3019,
          studentsMale: 210,
          studentsFemale: 231,
          totalStudents: 441,
          teachers: 28,
          classes: 15,
          capacity: 500,
          libraryPercentage: 90,
          scienceLabPercentage: 80,
          computerLabPercentage: 65,
          teacherRoomPercentage: 100,
          toiletPercentage: 75,
          worshipRoomPercentage: 85,
          isActive: true,
          subjects: [
            Subject(id: 1, name: 'Matematika'),
            Subject(id: 2, name: 'Bahasa Indonesia'),
            Subject(id: 3, name: 'IPA Terpadu'),
          ],
        ),
      PublicDataEntity.healthFacility =>
        const HealthFacility(
          id: 1,
          name: 'Puskesmas Kolonodale',
          facilityType: 'Puskesmas',
          kecamatan: 'Petasia',
          address: 'Jl. Trans Sulawesi KM 12',
          latitude: -2.5412,
          longitude: 121.3019,
          beds: 32,
          doctors: 6,
          nurses: 12,
          midwives: 9,
          status: 'aktif',
          phone: '0852-1234-5678',
          description: 'Melayani layanan kesehatan dasar 24 jam.',
        ),
      PublicDataEntity.polsek =>
        const Polsek(
          id: 1,
          name: 'Polsek Petasia',
          kecamatan: 'Petasia',
          address: 'Jl. Raya Kolonodale',
          latitude: -2.5412,
          longitude: 121.3019,
          personnelCount: 24,
          poskamlingCount: 15,
          status: 'aktif',
        ),
      PublicDataEntity.poskamling =>
        const Poskamling(
          id: 1,
          name: 'Poskamling Taronggo',
          kecamatan: 'Bungku Utara',
          kelurahan: 'Taronggo',
          latitude: -2.5412,
          longitude: 121.3019,
          status: 'aktif',
          isActive: true,
        ),
      PublicDataEntity.tipkamtikmas =>
        const Tipkamtikmas(
          id: 1,
          title: 'Laporan Keamanan Lingkungan',
          kecamatan: 'Petasia',
          kelurahan: 'Kolonodale',
          description:
              'Meningkatkan kewaspadaan masyarakat terhadap gangguan '
              'keamanan dan ketertiban masyarakat.',
          status: 'aktif',
          latitude: -2.5412,
          longitude: 121.3019,
        ),
      PublicDataEntity.market =>
        const Market(
          id: 1,
          name: 'Pasar Kolonodale',
          kecamatan: 'Petasia',
          address: 'Jl. Pasar Kolonodale',
          latitude: -2.5412,
          longitude: 121.3019,
          status: 'aktif',
        ),
      PublicDataEntity.kelurahan =>
        const Kelurahan(
          id: 1,
          name: 'Kelurahan Kolonodale',
          kecamatan: 'Petasia',
          code: '72.12.01.1001',
          latitude: -2.5412,
          longitude: 121.3019,
          population: 8567,
          status: 'aktif',
        ),
    };
  };
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required PublicDataEntity entity,
  double textScale = 1.0,
  Size size = const Size(360, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: PublicDataDetailScreen(entity: entity, id: 1, loader: _sample(entity)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  const pages = <PublicDataEntity, String>{
    PublicDataEntity.school: 'Identitas Sekolah',
    PublicDataEntity.healthFacility: 'Kapasitas & Tenaga Medis',
    PublicDataEntity.polsek: 'Kekuatan Satuan',
    PublicDataEntity.poskamling: 'Identitas Poskamling',
    PublicDataEntity.tipkamtikmas: 'Identitas',
    PublicDataEntity.market: 'Identitas Pasar',
    PublicDataEntity.kelurahan: 'Demografi',
  };

  for (final entry in pages.entries) {
    for (final scale in [1.0, 1.3, 1.6]) {
      testWidgets('${entry.key.type} detail renders clean at $scale',
          (tester) async {
        await _pumpDetail(tester, entity: entry.key, textScale: scale);

        expect(tester.takeException(), isNull);
        // The entity-specific informative section is present.
        expect(find.text(entry.value), findsOneWidget);
      });
    }
  }

  testWidgets('school detail shows sections, stats and infrastructure',
      (tester) async {
    await _pumpDetail(tester, entity: PublicDataEntity.school);

    expect(tester.takeException(), isNull);
    expect(find.text('Identitas Sekolah'), findsOneWidget);
    expect(find.text('Statistik Siswa & Guru'), findsOneWidget);
    expect(find.text('Sarana & Prasarana'), findsOneWidget);
    expect(find.text('Mata Pelajaran'), findsOneWidget);
    expect(find.text('441'), findsOneWidget); // total students KPI
    expect(find.text('Matematika'), findsOneWidget); // subject chip
  });

  testWidgets('health detail shows workforce breakdown', (tester) async {
    await _pumpDetail(tester, entity: PublicDataEntity.healthFacility);

    expect(tester.takeException(), isNull);
    expect(find.text('Identitas Fasilitas'), findsOneWidget);
    expect(find.text('27 tenaga kesehatan total'), findsOneWidget); // workforce
    expect(find.text('12'), findsOneWidget); // nurses KPI
  });

  testWidgets('narrow 320dp dark mode has no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: PublicDataDetailScreen(
          entity: PublicDataEntity.school,
          id: 1,
          loader: _sample(PublicDataEntity.school),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Sarana & Prasarana'), findsOneWidget);
  });
}