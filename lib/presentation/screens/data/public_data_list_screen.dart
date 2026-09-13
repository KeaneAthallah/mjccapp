import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/chart_data.dart';
import '../../../data/models/data_sector.dart';
import '../../../data/models/public_data_overview.dart';
import '../../providers/list_provider.dart';
import '../../providers/public_data_provider.dart';
import '../../providers/public_list_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_view.dart';
import '../../widgets/charts/app_charts.dart';
import '../../widgets/data_entity_tile.dart';
import '../map/map_screen.dart';
import 'public_data_detail_screen.dart';
import 'public_data_entity.dart';

/// Data Publik category screen: entity selector (for multi-entity sectors),
/// debounced search, paginated list and an inline list/map toggle.
class PublicDataListScreen extends StatefulWidget {
  const PublicDataListScreen({super.key, required this.sector});

  final DataSector sector;

  @override
  State<PublicDataListScreen> createState() => _PublicDataListScreenState();
}

class _PublicDataListScreenState extends State<PublicDataListScreen> {
  late List<PublicDataEntity> _entities;
  late PublicDataEntity _selected;
  late bool _hasEntities;

  final _searchController = TextEditingController();
  Timer? _debounce;

  ListProvider<dynamic>? _provider;

  @override
  void initState() {
    super.initState();
    _entities = PublicDataEntity.forSector(widget.sector);
    _hasEntities = _entities.isNotEmpty;
    if (_hasEntities) {
      _selected = _entities.first;
      _provider = _createProvider(_selected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider!.loadFirst();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _provider?.dispose();
    super.dispose();
  }

  ListProvider<dynamic> _createProvider(PublicDataEntity entity) {
    return switch (entity) {
      PublicDataEntity.school => PublicSchoolListProvider(),
      PublicDataEntity.healthFacility => PublicHealthListProvider(),
      PublicDataEntity.polsek => PublicPolsekListProvider(),
      PublicDataEntity.poskamling => PublicPoskamlingListProvider(),
      PublicDataEntity.tipkamtikmas => PublicTipkamtikmasListProvider(),
      PublicDataEntity.market => PublicMarketListProvider(),
      PublicDataEntity.kelurahan => PublicKelurahanListProvider(),
    };
  }

  void _selectEntity(PublicDataEntity entity) {
    if (entity == _selected) return;
    setState(() {
      _selected = entity;
      _provider?.dispose();
      _provider = _createProvider(entity);
      _searchController.clear();
    });
    _provider!.loadFirst();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _provider!.setSearch(value);
    });
  }

  void _openMap(BuildContext context) {
    // The map endpoint still groups markers by the three legacy sectors;
    // "fasilitas" (pasar/kelurahan) lives under "ketertiban" there.
    final mapSector = widget.sector == DataSector.fasilitas
        ? 'ketertiban'
        : widget.sector.value;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(initialSector: mapSector),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasEntities) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.sector.label)),
        body: const Center(
          child: AsyncEmptyView(message: 'Belum ada kategori data untuk sektor ini.'),
        ),
      );
    }

    final colors = AppThemeColors.of(context);
    final provider = _provider!;
    final overview = context.watch<PublicDataProvider>().overview;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sector.label),
        actions: [
          IconButton(
            tooltip: 'Lihat peta',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => _openMap(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (overview != null) _SectorSummary(sector: widget.sector, overview: overview),
          if (_entities.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _entities.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final entity = _entities[index];
                    final selected = entity == _selected;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(entity.icon, size: 16, color: selected ? Colors.white : entity.color),
                          const SizedBox(width: 4),
                          Text(entity.label),
                        ],
                      ),
                      selected: selected,
                      selectedColor: entity.color,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (_) => _selectEntity(entity),
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari ${_selected.label.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _provider!.setSearch('');
                          },
                        ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildList(provider)),
        ],
      ),
    );
  }

  Widget _buildList(ListProvider<dynamic> provider) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        if (provider.loading) {
          return const AsyncLoadingView();
        }
        if (provider.error != null) {
          return AsyncErrorView(message: provider.error!, onRetry: provider.loadFirst);
        }
        if (provider.isEmpty) {
          return AsyncEmptyView(
            message: 'Tidak ada data ${_selected.label.toLowerCase()}.',
            description: 'Coba ubah pencarian atau filter.',
          );
        }
        return RefreshIndicator(
          onRefresh: provider.loadFirst,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: provider.items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              if (index == provider.items.length) {
                return _buildLoader(provider);
              }
              final item = provider.items[index];
              return _entityCard(context, item);
            },
          ),
        );
      },
    );
  }

  Widget _entityCard(BuildContext context, dynamic item) {
    final label = (item as dynamic).name ?? (item as dynamic).title ?? '';
    final subtitle = _subtitleFor(item);
    return Material(
      color: AppThemeColors.of(context).surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _openDetail(context, item),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppThemeColors.of(context).cardBorder),
          ),
          child: DataEntityTile(
            name: '$label',
            subtitle: subtitle,
            icon: _selected.icon,
            color: _selected.color,
            status: _statusOf(item),
            onTap: null,
          ),
        ),
      ),
    );
  }

  String? _subtitleFor(dynamic item) {
    final kecamatan = (item as dynamic).kecamatan as String?;
    final type = _selected;
    final parts = <String>[];
    if (type == PublicDataEntity.school && (item).schoolType != null) {
      parts.add('${(item).schoolType}');
    }
    if (type == PublicDataEntity.healthFacility && (item).facilityType != null) {
      parts.add('${(item).facilityType}');
    }
    if (kecamatan != null && kecamatan.isNotEmpty) parts.add(kecamatan);
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String? _statusOf(dynamic item) => statusLabelFor(_selected, item);

  void _openDetail(BuildContext context, dynamic item) {
    final id = (item as dynamic).id as int;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicDataDetailScreen(entity: _selected, id: id),
      ),
    );
  }

  Widget _buildLoader(ListProvider<dynamic> provider) {
    if (provider.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _provider!.loadMore();
      });
    }
    return const SizedBox.shrink();
  }
}

/// Compact per-sector stat header: KPI tiles + a doughnut / horizontal bar so
/// each category screen shows real charts instead of a bare list.
class _SectorSummary extends StatelessWidget {
  const _SectorSummary({required this.sector, required this.overview});

  final DataSector sector;
  final PublicDataOverview overview;

  @override
  Widget build(BuildContext context) {
    final p = overview.pendidikan;
    final k = overview.kesehatan;
    final kt = overview.ketertiban;
    final f = overview.fasilitas;

    final (kpis, chart) = switch (sector) {
      DataSector.pendidikan => (
          <({String label, int value, Color color})>[
            (label: 'Sekolah', value: p.sekolah, color: AppColors.dataPendidikan),
            (label: 'Siswa', value: p.siswa, color: AppColors.emerald600),
            (label: 'Guru', value: p.guru, color: AppColors.blue600),
          ],
          AppCharts.doughnut(
            context: context,
            height: 160,
            chart: SingleSeriesChart(
              labels: const ['SD', 'SMP'],
              data: [p.sd.toDouble(), p.smp.toDouble()],
            ),
          ) as Widget?,
        ),
      DataSector.kesehatan => (
          <({String label, int value, Color color})>[
            (label: 'Faskes', value: k.faskes, color: AppColors.dataKesehatan),
            (label: 'Dokter', value: k.dokter, color: AppColors.red500),
            (label: 'Perawat', value: k.perawat, color: AppColors.blue600),
            (label: 'Bidan', value: k.bidan, color: AppColors.emerald600),
          ],
          HorizontalBarList(
            color: AppColors.dataKesehatan,
            items: [
              (label: 'Puskesmas', value: k.puskesmas, pct: null),
              (label: 'Pustu', value: k.pustu, pct: null),
              (label: 'Rumah Sakit', value: k.rs, pct: null),
              (label: 'Posyandu', value: k.posyandu, pct: null),
            ],
          ) as Widget?,
        ),
      DataSector.ketertiban => (
          <({String label, int value, Color color})>[
            (label: 'Polsek', value: kt.polsek, color: AppColors.dataKeamanan),
            (label: 'Poskamling', value: kt.poskamling, color: AppColors.dataKeamanan),
            (label: 'Tipkamtikmas', value: kt.tipkamtikmas, color: AppColors.red500),
          ],
          AppCharts.doughnut(
            context: context,
            height: 160,
            chart: SingleSeriesChart(
              labels: const ['Polsek', 'Poskamling', 'Tipkamtikmas'],
              data: [
                kt.polsek.toDouble(),
                kt.poskamling.toDouble(),
                kt.tipkamtikmas.toDouble(),
              ],
            ),
          ) as Widget?,
        ),
      DataSector.fasilitas => (
          <({String label, int value, Color color})>[
            (label: 'Pasar', value: f.pasar, color: AppColors.dataFasilitas),
            (label: 'Kecamatan', value: f.kecamatan, color: AppColors.amber600),
            (label: 'Kelurahan', value: f.kelurahan, color: AppColors.blue600),
            (label: 'Penduduk', value: f.penduduk, color: AppColors.emerald600),
          ],
          HorizontalBarList(
            color: AppColors.dataFasilitas,
            items: [
              (label: 'Kecamatan', value: f.kecamatan, pct: null),
              (label: 'Kelurahan', value: f.kelurahan, pct: null),
              (label: 'Pasar', value: f.pasar, pct: null),
            ],
          ) as Widget?,
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: AppCard(
        title: 'Ringkasan ${sector.label}',
        subtitle: 'Statistik terkini sektor ini',
        icon: sector.icon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final kpi in kpis)
                      SizedBox(width: tileWidth, child: _KpiTile(kpi: kpi)),
                  ],
                );
              },
            ),
            if (chart != null) ...[
              const SizedBox(height: AppSpacing.md),
              chart,
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.kpi});

  final ({String label, int value, Color color}) kpi;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
      decoration: BoxDecoration(
        color: kpi.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.number(kpi.value),
            style: TextStyle(
              color: kpi.color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}