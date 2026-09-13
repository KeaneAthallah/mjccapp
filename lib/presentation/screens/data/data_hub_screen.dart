import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/chart_data.dart';
import '../../../data/models/data_sector.dart';
import '../../../data/models/public_data_overview.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/public_data_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/charts/app_charts.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../map/map_screen.dart';
import 'public_data_list_screen.dart';

/// Data Publik hub — the first-class entry point for public sector data
/// (Pendidikan / Kesehatan / Ketertiban / Fasilitas Publik).
class DataHubScreen extends StatefulWidget {
  const DataHubScreen({super.key});

  @override
  State<DataHubScreen> createState() => _DataHubScreenState();
}

class _DataHubScreenState extends State<DataHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicDataProvider>().load();
      context.read<MasterDataProvider>().ensureLoaded().catchError((_) => []);
    });
  }

  void _openMap(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MapScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicDataProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Publik'),
        actions: [
          IconButton(
            tooltip: 'Lihat peta',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _openMap(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _HubBanner(),
            const SizedBox(height: AppSpacing.sectionGap),
            if (provider.error != null)
              AppErrorState(message: provider.error!, onRetry: provider.load),
            if (provider.loading && provider.overview == null)
              const AppDashboardLoading()
            else if (provider.overview != null) ...[
              _StatsSection(overview: provider.overview!),
              _SectorChartCard(overview: provider.overview!),
              _SectorGrid(overview: provider.overview!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gradient banner introducing the Data Publik hub.
class _HubBanner extends StatelessWidget {
  const _HubBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF134E4A), Color(0xFF0D9488), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.dataset_outlined, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Publik',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'PENDIDIKAN · KESEHATAN · KETERTIBAN · FASILITAS',
                      style: TextStyle(
                        color: Color(0xFF99F6E4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// KPI cards for the whole Data Publik dataset (mirrors the website layout).
class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.overview});

  final PublicDataOverview overview;

  void _openSector(BuildContext context, DataSector sector) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicDataListScreen(sector: sector)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = overview.pendidikan;
    final k = overview.kesehatan;
    final cards = <Widget>[
      StatCard(
        label: 'Sekolah',
        value: Formatters.number(p.sekolah),
        icon: Icons.school_outlined,
        color: AppColors.dataPendidikan,
        footer: '${Formatters.number(p.siswa)} siswa',
        onTap: () => _openSector(context, DataSector.pendidikan),
      ),
      StatCard(
        label: 'Guru',
        value: Formatters.number(p.guru),
        icon: Icons.groups_outlined,
        color: AppColors.emerald600,
        onTap: () => _openSector(context, DataSector.pendidikan),
      ),
      StatCard(
        label: 'Fasilitas Kesehatan',
        value: Formatters.number(k.faskes),
        icon: Icons.local_hospital_outlined,
        color: AppColors.dataKesehatan,
        onTap: () => _openSector(context, DataSector.kesehatan),
      ),
      StatCard(
        label: 'Tenaga Medis',
        value: Formatters.number(k.tenagaMedis),
        icon: Icons.medical_services_outlined,
        color: AppColors.blue600,
        footer: '${Formatters.number(k.dokter)} dokter',
        onTap: () => _openSector(context, DataSector.kesehatan),
      ),
      StatCard(
        label: 'Aspek Keamanan',
        value: Formatters.number(overview.ketertiban.total),
        icon: Icons.local_police_outlined,
        color: AppColors.dataKeamanan,
        onTap: () => _openSector(context, DataSector.ketertiban),
      ),
      StatCard(
        label: 'Fasilitas Umum',
        value: Formatters.number(overview.fasilitas.pasar),
        icon: Icons.storefront_outlined,
        color: AppColors.dataFasilitas,
        footer:
            '${overview.fasilitas.kelurahan} kelurahan · '
            '${Formatters.number(overview.fasilitas.penduduk)} penduduk',
        onTap: () => _openSector(context, DataSector.fasilitas),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

/// Sector composition doughnut ("Penyebaran Data per Sektor").
class _SectorChartCard extends StatelessWidget {
  const _SectorChartCard({required this.overview});

  final PublicDataOverview overview;

  @override
  Widget build(BuildContext context) {
    final o = overview;
    final entries =
        <({String label, String count, Color color, DataSector sector})>[
          (
            label: 'Pendidikan',
            count: Formatters.number(o.pendidikan.sekolah),
            color: AppColors.dataPendidikan,
            sector: DataSector.pendidikan,
          ),
          (
            label: 'Kesehatan',
            count: Formatters.number(o.kesehatan.faskes),
            color: AppColors.dataKesehatan,
            sector: DataSector.kesehatan,
          ),
          (
            label: 'Ketertiban',
            count: Formatters.number(o.ketertiban.total),
            color: AppColors.dataKeamanan,
            sector: DataSector.ketertiban,
          ),
          (
            label: 'Fasilitas',
            count: Formatters.number(o.fasilitas.pasar),
            color: AppColors.dataFasilitas,
            sector: DataSector.fasilitas,
          ),
        ];
    final chart = SingleSeriesChart(
      labels: [for (final e in entries) e.label],
      data: [
        o.pendidikan.sekolah.toDouble(),
        o.kesehatan.faskes.toDouble(),
        o.ketertiban.total.toDouble(),
        o.fasilitas.pasar.toDouble(),
      ],
    );

    return AppCard(
      icon: Icons.donut_large_outlined,
      title: 'Penyebaran Data per Sektor',
      subtitle: 'Komposisi seluruh data publik',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCharts.doughnut(context: context, chart: chart, height: 180),
          const SizedBox(height: AppSpacing.md),
          for (final entry in entries)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicDataListScreen(sector: entry.sector),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: entry.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          entry.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppThemeColors.of(context).textSecondary,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.count,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: entry.color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppThemeColors.of(context).textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Two-column sector cards, each opening its data category.
class _SectorGrid extends StatelessWidget {
  const _SectorGrid({required this.overview});

  final PublicDataOverview overview;

  @override
  Widget build(BuildContext context) {
    final cards = <_SectorData>[
      _SectorData(
        sector: DataSector.pendidikan,
        count: overview.pendidikan.sekolah,
        summary:
            '${Formatters.number(overview.pendidikan.siswa)} siswa · '
            '${Formatters.number(overview.pendidikan.guru)} guru',
      ),
      _SectorData(
        sector: DataSector.kesehatan,
        count: overview.kesehatan.faskes,
        summary:
            '${Formatters.number(overview.kesehatan.tenagaMedis)} tenaga '
            'kesehatan',
      ),
      _SectorData(
        sector: DataSector.ketertiban,
        count: overview.ketertiban.total,
        summary:
            '${overview.ketertiban.tipkamtikmas} tipkamtikmas · '
            '${overview.ketertiban.polsek} polsek',
      ),
      _SectorData(
        sector: DataSector.fasilitas,
        count: overview.fasilitas.pasar,
        summary:
            '${overview.fasilitas.kelurahan} kelurahan · '
            '${Formatters.number(overview.fasilitas.penduduk)} penduduk',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: _SectorCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _SectorData {
  const _SectorData({
    required this.sector,
    required this.count,
    required this.summary,
  });

  final DataSector sector;
  final int count;
  final String summary;
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({required this.data});

  final _SectorData data;

  @override
  Widget build(BuildContext context) {
    final sector = data.sector;
    final colors = AppThemeColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PublicDataListScreen(sector: sector),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sector.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(sector.icon, color: sector.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: AppStatusBadge(
                          label: Formatters.number(data.count),
                          color: sector.color,
                          icon: Icons.tag,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sector.label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
