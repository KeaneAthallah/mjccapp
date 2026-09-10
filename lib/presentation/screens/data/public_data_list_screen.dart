import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/data_sector.dart';
import '../../providers/list_provider.dart';
import '../../providers/public_list_providers.dart';
import '../../widgets/async_view.dart';
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

  final _searchController = TextEditingController();
  Timer? _debounce;

  ListProvider<dynamic>? _provider;

  @override
  void initState() {
    super.initState();
    _entities = PublicDataEntity.forSector(widget.sector);
    _selected = _entities.first;
    _provider = _createProvider(_selected);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider!.loadFirst();
    });
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
    final colors = AppThemeColors.of(context);
    final provider = _provider!;

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

  String? _statusOf(dynamic item) {
    return (item as dynamic).status as String?;
  }

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