import 'package:flutter/material.dart';

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
/// layout per entity type.
class PublicDataDetailScreen extends StatefulWidget {
  const PublicDataDetailScreen({super.key, required this.entity, required this.id});

  final PublicDataEntity entity;
  final int id;

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
      final item = await switch (widget.entity) {
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
          PublicDataEntity.school => _schoolCard(item as School),
          PublicDataEntity.healthFacility => _healthCard(item as HealthFacility),
          PublicDataEntity.polsek => _polsekCard(item as Polsek),
          PublicDataEntity.poskamling => _poskamlingCard(item as Poskamling),
          PublicDataEntity.tipkamtikmas => _tipkamtikmasCard(item as Tipkamtikmas),
          PublicDataEntity.market => _marketCard(item as Market),
          PublicDataEntity.kelurahan => _kelurahanCard(item as Kelurahan),
        },
      ],
    );
  }

  Widget _header(Object item) {
    final name = (item as dynamic).name ?? (item as dynamic).title ?? '-';
    final status = _statusOf(item);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: widget.entity.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(widget.entity.icon, color: widget.entity.color, size: 28),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$name',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              if (status != null && status.isNotEmpty) ...[
                const SizedBox(height: 4),
                AppStatusBadge(label: status, tone: AppStatusBadge.toneFrom(status)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _statusOf(Object item) {
    return (item as dynamic).status as String?;
  }

  Widget _schoolCard(School item) {
    final percentages = [
      ('Perpustakaan', item.libraryPercentage),
      ('Lab IPA', item.scienceLabPercentage),
      ('Lab Komputer', item.computerLabPercentage),
      ('Ruang Guru', item.teacherRoomPercentage),
      ('Toilet', item.toiletPercentage),
      ('Ruang Ibadah', item.worshipRoomPercentage),
    ];
    return AppCard(
      title: 'Rincian Sekolah',
      icon: widget.entity.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: 'NPSN', value: item.npsn),
          AppInfoRow(label: 'Jenjang', value: item.schoolType),
          AppInfoRow(label: 'Kecamatan', value: item.kecamatan),
          AppInfoRow(label: 'Kelurahan', value: item.kelurahan),
          AppInfoRow(label: 'Alamat', value: item.address),
          AppInfoRow(
            label: 'Siswa',
            value: '${Formatters.number(item.totalStudents)} '
                '(P ${Formatters.number(item.studentsFemale)} / '
                'L ${Formatters.number(item.studentsMale)})',
          ),
          AppInfoRow(label: 'Guru', value: Formatters.number(item.teachers)),
          AppInfoRow(label: 'Rombel', value: Formatters.number(item.classes)),
          AppInfoRow(label: 'Kapasitas', value: Formatters.number(item.capacity)),
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
          for (final (label, value) in percentages)
            AppInfoRow(label: label, value: _percent(value)),
        ],
      ),
    );
  }

  String _percent(double? value) => value == null ? '-' : '${value.toStringAsFixed(0)}%';

  Widget _healthCard(HealthFacility item) {
    return AppCard(
      title: 'Rincian Fasilitas Kesehatan',
      icon: widget.entity.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: 'Jenis', value: item.facilityType),
          AppInfoRow(label: 'Kecamatan', value: item.kecamatan),
          AppInfoRow(label: 'Alamat', value: item.address),
          AppInfoRow(label: 'Telepon', value: item.phone),
          AppInfoRow(label: 'Tempat Tidur', value: Formatters.number(item.beds)),
          AppInfoRow(label: 'Dokter', value: Formatters.number(item.doctors)),
          AppInfoRow(label: 'Perawat', value: Formatters.number(item.nurses)),
          AppInfoRow(label: 'Bidan', value: Formatters.number(item.midwives)),
          if (item.description != null && item.description!.isNotEmpty)
            AppInfoRow(label: 'Deskripsi', value: item.description),
        ],
      ),
    );
  }

  Widget _polsekCard(Polsek item) {
    return AppCard(
      title: 'Rincian Polsek',
      icon: widget.entity.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: 'Kecamatan', value: item.kecamatan),
          AppInfoRow(label: 'Alamat', value: item.address),
          AppInfoRow(label: 'Personel', value: Formatters.number(item.personnelCount)),
          AppInfoRow(label: 'Poskamling', value: Formatters.number(item.poskamlingCount)),
        ],
      ),
    );
  }

  Widget _poskamlingCard(Poskamling item) {
    return AppCard(
      title: 'Rincian Poskamling',
      icon: widget.entity.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: 'Kecamatan', value: item.kecamatan),
          AppInfoRow(label: 'Kelurahan', value: item.kelurahan),
          AppInfoRow(
            label: 'Status',
            valueWidget: Text(
              item.status ?? '-',
              style: TextStyle(color: AppThemeColors.of(context).textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipkamtikmasCard(Tipkamtikmas item) {
    return AppCard(
      title: 'Rincian Tipkamtikmas',
      icon: widget.entity.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: 'Kecamatan', value: item.kecamatan),
          AppInfoRow(label: 'Kelurahan', value: item.kelurahan),
          AppInfoRow(label: 'Deskripsi', value: item.description),
        ],
      ),
    );
  }

  Widget _marketCard(Market item) {
    return AppCard(
      title: 'Rincian Pasar',
      icon: widget.entity.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: 'Kecamatan', value: item.kecamatan),
          AppInfoRow(label: 'Alamat', value: item.address),
        ],
      ),
    );
  }

  Widget _kelurahanCard(Kelurahan item) {
    return AppCard(
      title: 'Rincian Kelurahan',
      icon: widget.entity.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: 'Kode', value: item.code),
          AppInfoRow(label: 'Kecamatan', value: item.kecamatan),
          AppInfoRow(label: 'Penduduk', value: Formatters.number(item.population)),
          AppInfoRow(label: 'Status', value: item.status),
        ],
      ),
    );
  }
}