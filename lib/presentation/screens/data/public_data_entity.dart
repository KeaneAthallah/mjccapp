import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/data_sector.dart';

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