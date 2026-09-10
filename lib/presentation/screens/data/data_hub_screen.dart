import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/data_sector.dart';
import '../../../data/models/public_data_overview.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/public_data_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_status_badge.dart';
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicDataProvider>();

    return RefreshIndicator(
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
            _SectorGrid(overview: provider.overview!),
          ],
        ],
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
        summary: '${Formatters.number(overview.pendidikan.siswa)} siswa · '
            '${Formatters.number(overview.pendidikan.guru)} guru',
      ),
      _SectorData(
        sector: DataSector.kesehatan,
        count: overview.kesehatan.faskes,
        summary: '${Formatters.number(overview.kesehatan.tenagaMedis)} tenaga '
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
              SizedBox(width: cardWidth, child: _SectorCard(data: card)),
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
                  const Spacer(),
                  AppStatusBadge(
                    label: Formatters.number(data.count),
                    color: sector.color,
                    icon: Icons.tag,
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