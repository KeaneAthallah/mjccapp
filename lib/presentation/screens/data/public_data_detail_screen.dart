import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/health_facility.dart';
import '../../../data/models/kelurahan.dart';
import '../../../data/models/market.dart';
import '../../../data/models/polsek.dart';
import '../../../data/models/poskamling.dart';
import '../../../data/models/school.dart';
import '../../../data/models/tipkamtikmas.dart';
import '../../../data/repositories/repositories.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/async_view.dart';
import 'public_data_entity.dart';

/// Read-only detail page for a single public record, adapting its field
/// layout per entity type. Each type gets multiple sectioned cards (identity,
/// statistics, infrastructure/demographics) so real records feel informative.
class PublicDataDetailScreen extends StatefulWidget {
  const PublicDataDetailScreen({
    super.key,
    required this.entity,
    required this.id,
    this.loader,
  });

  final PublicDataEntity entity;
  final int id;

  /// Test/DI seam: overrides the default public-API fetch (which uses
  /// [Repositories.instance]) so widget tests can render real records.
  final Future<Object> Function(PublicDataEntity entity, int id)? loader;

  @override
  State<PublicDataDetailScreen> createState() => _PublicDataDetailScreenState();
}

class _PublicDataDetailScreenState extends State<PublicDataDetailScreen> {
  Object? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = widget.loader != null
          ? await widget.loader!(widget.entity, widget.id)
          : await _fetch();
      if (!mounted) return;
      setState(() {
        _item = item;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat detail data. Periksa koneksi Anda.';
        _loading = false;
      });
    }
  }

  Future<Object> _fetch() {
    return switch (widget.entity) {
      PublicDataEntity.school =>
        Repositories.instance.publicData.schools.show(widget.id),
      PublicDataEntity.healthFacility =>
        Repositories.instance.publicData.healthFacilities.show(widget.id),
      PublicDataEntity.polsek =>
        Repositories.instance.publicData.polseks.show(widget.id),
      PublicDataEntity.poskamling =>
        Repositories.instance.publicData.poskamlings.show(widget.id),
      PublicDataEntity.tipkamtikmas =>
        Repositories.instance.publicData.tipkamtikmas.show(widget.id),
      PublicDataEntity.market =>
        Repositories.instance.publicData.markets.show(widget.id),
      PublicDataEntity.kelurahan =>
        Repositories.instance.publicData.kelurahans.show(widget.id),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.entity.label)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AsyncLoadingView();
    if (_error != null) {
      return AsyncErrorView(message: _error!, onRetry: _load);
    }
    final item = _item!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _header(item),
        const SizedBox(height: AppSpacing.sectionGap),
        switch (widget.entity) {
          PublicDataEntity.school => _schoolPage(item as School),
          PublicDataEntity.healthFacility => _healthPage(item as HealthFacility),
          PublicDataEntity.polsek => _polsekPage(item as Polsek),
          PublicDataEntity.poskamling => _poskamlingPage(item as Poskamling),
          PublicDataEntity.tipkamtikmas => _tipkamtikmasPage(item as Tipkamtikmas),
          PublicDataEntity.market => _marketPage(item as Market),
          PublicDataEntity.kelurahan => _kelurahanPage(item as Kelurahan),
        },
      ],
    );
  }

  String? _headerName(Object item) {
    if (item is Tipkamtikmas) return item.title ?? '-';
    final n = (item as dynamic).name;
    return (n as String?) ?? '-';
  }

  Widget _header(Object item) {
    final name = _headerName(item);
    final status = _statusOf(item);
    final subtitle = _entitySubtitle(item);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.entity.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(widget.entity.icon, color: widget.entity.color, size: 30),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppThemeColors.of(context).textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (status != null && status.isNotEmpty) ...[
                const SizedBox(height: 6),
                AppStatusBadge(label: status, tone: AppStatusBadge.toneFrom(status)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _entitySubtitle(Object item) {
    final kecamatan = (item as dynamic).kecamatan as String?;
    String? type;
    if (item is School) {
      type = item.schoolType;
    } else if (item is HealthFacility) {
      type = item.facilityType;
    }
    final parts = [?type, ?kecamatan];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String? _statusOf(Object item) => statusLabelFor(widget.entity, item);

  String _coord(double? lat, double? lng) {
    if (lat == null || lng == null) return '-';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  // --- Sekolah -----------------------------------------------------------

  Widget _schoolPage(School item) {
    final percentages = [
      ('Perpustakaan', item.libraryPercentage),
      ('Lab IPA', item.scienceLabPercentage),
      ('Lab Komputer', item.computerLabPercentage),
      ('Ruang Guru', item.teacherRoomPercentage),
      ('Toilet', item.toiletPercentage),
      ('Ruang Ibadah', item.worshipRoomPercentage),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'Identitas Sekolah',
          subtitle: 'Data pokok lembaga pendidikan',
          icon: Icons.badge_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInfoRow(label: 'NPSN', icon: Icons.pin_outlined, value: item.npsn),
              AppInfoRow(label: 'Jenjang', icon: Icons.school_outlined, value: item.schoolType),
              AppInfoRow(label: 'Kecamatan', icon: Icons.map_outlined, value: item.kecamatan),
              AppInfoRow(label: 'Kelurahan', icon: Icons.location_city_outlined, value: item.kelurahan),
              AppInfoRow(label: 'Alamat', icon: Icons.place_outlined, value: item.address),
              AppInfoRow(
                label: 'Koordinat',
                icon: Icons.my_location_outlined,
                value: _coord(item.latitude, item.longitude),
              ),
            ],
          ),
        ),
        AppCard(
          title: 'Statistik Siswa & Guru',
          subtitle: 'Kondisi pembelajaran pada sektor ini',
          icon: Icons.groups_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kpiGrid(context, [
                _DetailKpi(
                  icon: Icons.people_outline,
                  value: Formatters.number(item.totalStudents),
                  label: 'Total Siswa',
                  color: AppColors.dataPendidikan,
                ),
                _DetailKpi(
                  icon: Icons.badge_outlined,
                  value: Formatters.number(item.teachers),
                  label: 'Guru',
                  color: AppColors.blue600,
                ),
                _DetailKpi(
                  icon: Icons.meeting_room_outlined,
                  value: Formatters.number(item.classes),
                  label: 'Rombongan Belajar',
                  color: AppColors.amber600,
                ),
                _DetailKpi(
                  icon: Icons.weekend_outlined,
                  value: Formatters.number(item.capacity),
                  label: 'Kapasitas',
                  color: AppColors.emerald600,
                ),
              ]),
              const SizedBox(height: AppSpacing.sm),
              _SplitRow(
                label: 'Siswa Perempuan',
                value: item.studentsFemale,
                color: AppColors.red500,
                suffix: 'orang',
              ),
              _SplitRow(
                label: 'Siswa Laki-laki',
                value: item.studentsMale,
                color: AppColors.blue600,
                suffix: 'orang',
              ),
            ],
          ),
        ),
        AppCard(
          title: 'Sarana & Prasarana',
          subtitle: 'Ketersediaan fasilitas sesuai standar',
          icon: Icons.handyman_outlined,
          child: Column(
            children: [
              for (final (label, value) in percentages)
                _LabeledBar(label: label, percent: value, color: AppColors.dataPendidikan),
            ],
          ),
        ),
        _schoolSubjectsCard(item),
      ],
    );
  }

  Widget _schoolSubjectsCard(School item) {
    final subjects = item.subjects.where((s) => s.name != null).toList();
    if (subjects.isEmpty) return const SizedBox.shrink();
    return AppCard(
      title: 'Mata Pelajaran',
      subtitle: '${subjects.length} mata pelajaran',
      icon: Icons.menu_book_outlined,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final subject in subjects)
            Chip(
              label: Text(subject.name!),
              side: BorderSide.none,
              backgroundColor: AppColors.dataPendidikan.withValues(alpha: 0.10),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.dataPendidikan,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }

  // --- Fasilitas Kesehatan -------------------------------------------------

  Widget _healthPage(HealthFacility item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'Identitas Fasilitas',
          subtitle: item.facilityType,
          icon: Icons.local_hospital_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInfoRow(label: 'Jenis', icon: Icons.category_outlined, value: item.facilityType),
              AppInfoRow(label: 'Status', icon: Icons.verified_outlined, value: item.status),
              AppInfoRow(label: 'Telepon', icon: Icons.phone_outlined, value: item.phone),
              AppInfoRow(label: 'Alamat', icon: Icons.place_outlined, value: item.address),
              AppInfoRow(
                label: 'Koordinat',
                icon: Icons.my_location_outlined,
                value: _coord(item.latitude, item.longitude),
              ),
            ],
          ),
        ),
        AppCard(
          title: 'Kapasitas & Tenaga Medis',
          subtitle: '${Formatters.number(item.workforce)} tenaga kesehatan total',
          icon: Icons.medical_services_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kpiGrid(context, [
                _DetailKpi(
                  icon: Icons.hotel_outlined,
                  value: Formatters.number(item.beds),
                  label: 'Tempat Tidur',
                  color: AppColors.dataKesehatan,
                ),
                _DetailKpi(
                  icon: Icons.medical_services_outlined,
                  value: Formatters.number(item.doctors),
                  label: 'Dokter',
                  color: AppColors.red600,
                ),
                _DetailKpi(
                  icon: Icons.support_agent_outlined,
                  value: Formatters.number(item.nurses),
                  label: 'Perawat',
                  color: AppColors.blue600,
                ),
                _DetailKpi(
                  icon: Icons.pregnant_woman_outlined,
                  value: Formatters.number(item.midwives),
                  label: 'Bidan',
                  color: AppColors.emerald600,
                ),
              ]),
            ],
          ),
        ),
        if (item.description != null && item.description!.isNotEmpty)
          AppCard(
            title: 'Deskripsi',
            icon: Icons.notes_outlined,
            child: Text(
              item.description!,
              style: TextStyle(
                color: AppThemeColors.of(context).textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  // --- Polsek --------------------------------------------------------------

  Widget _polsekPage(Polsek item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'Identitas Polsek',
          subtitle: 'Satuan Kepolisian Sektor',
          icon: Icons.local_police_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInfoRow(label: 'Kecamatan', icon: Icons.map_outlined, value: item.kecamatan),
              AppInfoRow(label: 'Alamat', icon: Icons.place_outlined, value: item.address),
              AppInfoRow(label: 'Status', icon: Icons.verified_outlined, value: item.status),
              AppInfoRow(
                label: 'Koordinat',
                icon: Icons.my_location_outlined,
                value: _coord(item.latitude, item.longitude),
              ),
            ],
          ),
        ),
        AppCard(
          title: 'Kekuatan Satuan',
          subtitle: 'Personel dan pos kamling dalam koordinasi',
          icon: Icons.shield_outlined,
          child: _kpiGrid(context, [
            _DetailKpi(
              icon: Icons.person_outline,
              value: Formatters.number(item.personnelCount),
              label: 'Personel',
              color: AppColors.dataKeamanan,
            ),
            _DetailKpi(
              icon: Icons.visibility_outlined,
              value: Formatters.number(item.poskamlingCount),
              label: 'Poskamling',
              color: AppColors.blue600,
            ),
          ]),
        ),
      ],
    );
  }

  // --- Poskamling ----------------------------------------------------------

  Widget _poskamlingPage(Poskamling item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'Identitas Poskamling',
          subtitle: 'Pos Keamanan Lingkungan',
          icon: Icons.visibility_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInfoRow(label: 'Kecamatan', icon: Icons.map_outlined, value: item.kecamatan),
              AppInfoRow(label: 'Kelurahan', icon: Icons.location_city_outlined, value: item.kelurahan),
              AppInfoRow(label: 'Status', icon: Icons.verified_outlined, value: item.status),
              AppInfoRow(
                label: 'Keaktifan',
                icon: Icons.toggle_on_outlined,
                valueWidget: _boolBadge(item.isActive),
              ),
              AppInfoRow(
                label: 'Koordinat',
                icon: Icons.my_location_outlined,
                value: _coord(item.latitude, item.longitude),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tipkamtikmas ---------------------------------------------------------

  Widget _tipkamtikmasPage(Tipkamtikmas item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'Identitas',
          subtitle: 'Informasi Tipkamtikmas',
          icon: Icons.report_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInfoRow(label: 'Kecamatan', icon: Icons.map_outlined, value: item.kecamatan),
              AppInfoRow(label: 'Kelurahan', icon: Icons.location_city_outlined, value: item.kelurahan),
              AppInfoRow(label: 'Status', icon: Icons.verified_outlined, value: item.status),
              AppInfoRow(
                label: 'Koordinat',
                icon: Icons.my_location_outlined,
                value: _coord(item.latitude, item.longitude),
              ),
            ],
          ),
        ),
        if (item.description != null && item.description!.isNotEmpty)
          AppCard(
            title: 'Keterangan',
            icon: Icons.notes_outlined,
            child: Text(
              item.description!,
              style: TextStyle(
                color: AppThemeColors.of(context).textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  // --- Pasar ---------------------------------------------------------------

  Widget _marketPage(Market item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'Identitas Pasar',
          subtitle: 'Pasar rakyat / pusat perdagangan',
          icon: Icons.storefront_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInfoRow(label: 'Kecamatan', icon: Icons.map_outlined, value: item.kecamatan),
              AppInfoRow(label: 'Alamat', icon: Icons.place_outlined, value: item.address),
              AppInfoRow(label: 'Status', icon: Icons.verified_outlined, value: item.status),
              AppInfoRow(
                label: 'Koordinat',
                icon: Icons.my_location_outlined,
                value: _coord(item.latitude, item.longitude),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Kelurahan -----------------------------------------------------------

  Widget _kelurahanPage(Kelurahan item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          title: 'Identitas Kelurahan',
          subtitle: 'Wilayah administrasi tingkat kelurahan',
          icon: Icons.location_city_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInfoRow(label: 'Kode', icon: Icons.tag_outlined, value: item.code),
              AppInfoRow(label: 'Kecamatan', icon: Icons.map_outlined, value: item.kecamatan),
              AppInfoRow(label: 'Status', icon: Icons.verified_outlined, value: item.status),
              AppInfoRow(
                label: 'Koordinat',
                icon: Icons.my_location_outlined,
                value: _coord(item.latitude, item.longitude),
              ),
            ],
          ),
        ),
        AppCard(
          title: 'Demografi',
          subtitle: 'Jumlah penduduk di wilayah ini',
          icon: Icons.bar_chart_outlined,
          child: _kpiGrid(context, [
            _DetailKpi(
              icon: Icons.people_outline,
              value: Formatters.number(item.population),
              label: 'Total Penduduk',
              color: AppColors.dataFasilitas,
            ),
          ]),
        ),
      ],
    );
  }

  // --- Shared helpers ------------------------------------------------------

  Widget _kpiGrid(BuildContext context, List<Widget> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final tile in tiles) SizedBox(width: tileWidth, child: tile)],
        );
      },
    );
  }

  Widget _boolBadge(bool? value) {
    if (value == null) {
      return Text('-', style: TextStyle(color: AppThemeColors.of(context).textMuted, fontSize: 13));
    }
    return AppStatusBadge(
      label: value ? 'Aktif' : 'Tidak aktif',
      tone: value ? BadgeTone.green : BadgeTone.red,
    );
  }
}

/// Compact tinted KPI tile (icon + value + label) used across detail pages.
class _DetailKpi extends StatelessWidget {
  const _DetailKpi({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label with a trailing formatted count, e.g. "Siswa Perempuan · 1.234 orang".
class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.label,
    required this.value,
    required this.color,
    this.suffix = '',
  });

  final String label;
  final int? value;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          Text(
            Formatters.number(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          if (suffix.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(suffix, style: TextStyle(fontSize: 11, color: colors.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// Labeled percentage progress bar (school infrastructure availability).
class _LabeledBar extends StatelessWidget {
  const _LabeledBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double? percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final clamped = percent == null ? 0.0 : (percent! / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                percent == null
                    ? 'Tidak tersedia'
                    : '${percent!.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: percent == null ? colors.textMuted : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
              color: color,
              backgroundColor: colors.surfaceAlt,
            ),
          ),
        ],
      ),
    );
  }
}