import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// One of the four public sector (sector) categories in the redesigned app:
/// Pendidikan, Kesehatan, Ketertiban, Fasilitas Publik.
///
/// Maps the Laravel `sector` strings to presentation metadata (label, icon,
/// brand color) so the Data hub, lists, detail pages and map stay consistent.
enum DataSector {
  pendidikan('pendidikan', 'Pendidikan', Icons.school_outlined, AppColors.dataPendidikan),
  kesehatan('kesehatan', 'Kesehatan', Icons.medical_services_outlined, AppColors.dataKesehatan),
  ketertiban('ketertiban', 'Ketertiban', Icons.local_police_outlined, AppColors.dataKeamanan),
  fasilitas('fasilitas', 'Fasilitas Publik', Icons.storefront_outlined, AppColors.dataFasilitas);

  const DataSector(this.value, this.label, this.icon, this.color);

  /// The `sector` used by the Laravel `/maps` endpoint.
  final String value;

  final String label;
  final IconData icon;
  final Color color;

  static DataSector? fromValue(String? value) {
    return DataSector.values.where((s) => s.value == value).firstOrNull;
  }
}

/// Entity type constants used across map markers and public lists.
abstract final class DataEntityType {
  static const String school = 'school';
  static const String healthFacility = 'health_facility';
  static const String polsek = 'polsek';
  static const String poskamling = 'poskamling';
  static const String tipkamtikmas = 'tipkamtikmas';
  static const String market = 'market';
  static const String kelurahan = 'kelurahan';
}