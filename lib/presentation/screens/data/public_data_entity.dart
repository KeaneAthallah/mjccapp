import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/data_sector.dart';
import '../../../data/models/school.dart';

/// The concrete "sub-resources" browsable inside each Data sector.
enum PublicDataEntity {
  school(
    DataEntityType.school,
    DataSector.pendidikan,
    'Sekolah',
    Icons.school_outlined,
    AppColors.dataPendidikan,
  ),
  healthFacility(
    DataEntityType.healthFacility,
    DataSector.kesehatan,
    'Fasilitas Kesehatan',
    Icons.local_hospital_outlined,
    AppColors.dataKesehatan,
  ),
  polsek(
    DataEntityType.polsek,
    DataSector.ketertiban,
    'Polsek',
    Icons.local_police_outlined,
    AppColors.dataKeamanan,
  ),
  poskamling(
    DataEntityType.poskamling,
    DataSector.ketertiban,
    'Poskamling',
    Icons.visibility_outlined,
    AppColors.dataKeamanan,
  ),
  tipkamtikmas(
    DataEntityType.tipkamtikmas,
    DataSector.ketertiban,
    'Tipkamtikmas',
    Icons.report_outlined,
    AppColors.dataKeamanan,
  ),
  market(
    DataEntityType.market,
    DataSector.fasilitas,
    'Pasar',
    Icons.storefront_outlined,
    AppColors.dataFasilitas,
  ),
  kelurahan(
    DataEntityType.kelurahan,
    DataSector.fasilitas,
    'Kelurahan',
    Icons.location_city_outlined,
    AppColors.dataFasilitas,
  );

  const PublicDataEntity(this.type, this.sector, this.label, this.icon, this.color);

  final String type;
  final DataSector sector;
  final String label;
  final IconData icon;
  final Color color;

  /// The canonical order of entities inside each sector.
  static List<PublicDataEntity> forSector(DataSector sector) {
    return values.where((e) => e.sector == sector).toList();
  }
}

/// Public status label for a record.
///
/// Most entities expose a `status` field, but `School` does not (it exposes a
/// nullable `isActive` instead). Guarding that case prevents a
/// `NoSuchMethodError` from `(item as dynamic).status` at build time, which
/// used to blank out the Pendidikan list as soon as real school rows rendered.
String? statusLabelFor(PublicDataEntity entity, Object item) {
  if (entity == PublicDataEntity.school) {
    final school = item as School;
    final active = school.isActive;
    if (active == null) return null;
    return active ? 'Aktif' : 'Tidak aktif';
  }
  return (item as dynamic).status as String?;
}