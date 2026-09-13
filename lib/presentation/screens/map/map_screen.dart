import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/map_data.dart';
import '../../../data/models/sos_alert.dart';
import '../../providers/map_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_status_badge.dart';
import '../sos/sos_detail_screen.dart';

/// Map screen: interactive OpenStreetMap with sector/type/kecamatan filters
/// plus a live overlay of open SOS emergency incidents.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialSector = ''});

  /// Sector to select on first load, e.g. when opened from the Data hub
  /// (`pendidikan`, `kesehatan`, `ketertiban`). Empty = all sectors.
  final String initialSector;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  static const _sectors = <({String key, String label, IconData? icon, Color color})>[
    (key: '', label: 'Semua Sektor', icon: null, color: AppColors.gray600),
    (key: 'pendidikan', label: 'Pendidikan', icon: Icons.school_outlined, color: AppColors.dataPendidikan),
    (key: 'kesehatan', label: 'Kesehatan', icon: Icons.medical_services_outlined, color: AppColors.dataKesehatan),
    (key: 'ketertiban', label: 'Ketertiban', icon: Icons.local_police_outlined, color: AppColors.dataKeamanan),
  ];

  static const _types = {
    'pendidikan': [('', 'Semua'), ('school', 'Sekolah')],
    'kesehatan': [('', 'Semua'), ('health', 'Fasilitas Kesehatan')],
    'ketertiban': [
      ('', 'Semua'),
      ('polsek', 'Polsek'),
      ('tipkamtikmas', 'Tipkamtikmas'),
      ('poskamling', 'Poskamling'),
      ('market', 'Pasar'),
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSector.isNotEmpty) {
        context.read<MapProvider>().setSector(widget.initialSector);
      }
      context.read<MapProvider>().load();
      context.read<MasterDataProvider>().ensureLoaded().catchError((_) => []);
      context.read<SosProvider>().loadActiveIncidents(silent: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapProvider>();
    final master = context.watch<MasterDataProvider>();
    final sos = context.watch<SosProvider>();
    final empty =
        !map.loading && map.error == null &&
        (map.data?.markers ?? []).isEmpty &&
        sos.activeIncidents.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Peta MJCC')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(map),
          Positioned(top: 8, left: 0, right: 0, child: _buildTopFilters(map, master)),
          if (empty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(999),
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_outlined, size: 18, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 8),
                        const Text('Tidak ada lokasi untuk filter ini.'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (map.loading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          if (map.error != null)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: _MapError(message: map.error!, onRetry: map.load),
              ),
            ),
        ],
      ),
    );
  }

  /// Compact floating filter controls pinned to the top of the map.
  Widget _buildTopFilters(MapProvider map, MasterDataProvider master) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _floatingChipRow(
          children: [
            for (final sector in _sectors)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ChoiceChip(
                  showCheckmark: false,
                  avatar: sector.icon == null
                      ? null
                      : Icon(
                          sector.icon,
                          size: 15,
                          color: map.sector == sector.key
                              ? Colors.white
                              : sector.color,
                        ),
                  label: Text(sector.label),
                  selected: map.sector == sector.key,
                  selectedColor: sector.color,
                  labelStyle: TextStyle(
                    color: _chip(Theme.of(context), sector),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => map.setSector(sector.key),
                ),
              ),
          ],
        ),
        if (map.sector.isNotEmpty) ...[
          const SizedBox(height: 6),
          _floatingChipRow(
            children: [
              for (final type in _types[map.sector]!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    showCheckmark: false,
                    label: Text(type.$2),
                    selected: map.type == type.$1,
                    selectedColor: _sectorColor(map.sector),
                    labelStyle: TextStyle(
                      color: map.type == type.$1
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => map.setType(type.$1),
                  ),
                ),
            ],
          ),
        ],
        if (master.kecamatans != null && master.kecamatans!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(999),
              color: Theme.of(context).colorScheme.surface,
              child: FilterChip(
                showCheckmark: false,
                avatar: Icon(
                  Icons.place_outlined,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(_kecamatanLabel(master, map.kecamatanId)),
                selected: map.kecamatanId != null,
                selectedColor: AppColors.emerald600,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => _pickKecamatan(map, master),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Horizontally scrollable row of chip filters on a floating surface.
  Widget _floatingChipRow({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(children: children),
        ),
      ),
    );
  }

  String _kecamatanLabel(MasterDataProvider master, int? id) {
    if (id == null) return 'Semua Kecamatan';
    final kecamatans = master.kecamatans;
    if (kecamatans == null) return 'Kecamatan';
    for (final k in kecamatans) {
      if (k.id == id) return k.name ?? 'Kecamatan';
    }
    return 'Kecamatan';
  }

  Future<void> _pickKecamatan(MapProvider map, MasterDataProvider master) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final selected = map.kecamatanId;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Pilih Kecamatan',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public, color: AppColors.dataPendidikan),
                title: const Text('Semua Kecamatan'),
                trailing: selected == null
                    ? const Icon(Icons.check_circle, color: AppColors.emerald600)
                    : null,
                onTap: () => Navigator.pop(ctx, -1),
              ),
              for (final k in master.kecamatans!)
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(k.name ?? '-'),
                  trailing: selected == k.id
                      ? const Icon(Icons.check_circle, color: AppColors.emerald600)
                      : null,
                  onTap: () => Navigator.pop(ctx, k.id),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null) {
      map.setKecamatan(chosen == -1 ? null : chosen);
    }
  }

  Widget _buildMap(MapProvider map) {
    final markers = map.data?.markers ?? [];
    final incidents = context.watch<SosProvider>().activeIncidents;

    MapOptions options() => MapOptions(
          initialCenter: const LatLng(-2.1833, 121.4833),
          initialZoom: 10,
          minZoom: 6,
          maxZoom: 18,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        );

    return FlutterMap(
      mapController: _mapController,
      options: options(),
      children: [
        _tileLayer(),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final m in markers)
                if (m.hasCoordinates)
                  Marker(
                    point: LatLng(m.latitude!, m.longitude!),
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _showDetail(context, m),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            _colorFor(m.type).withValues(alpha: 0.25),
                        child: Icon(
                          _iconFor(m.type),
                          size: 18,
                          color: _colorFor(m.type),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        if (incidents.isNotEmpty)
          MarkerLayer(
            markers: [
              for (final incident in incidents.where((a) => a.isOpen))
                Marker(
                  point: LatLng(incident.latitude, incident.longitude),
                  width: 34,
                  height: 34,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SosDetailScreen(alertId: incident.id),
                      ),
                    ),
                    child: _IncidentPin(incident: incident),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  TileLayer _tileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'id.go.morowali.mjcc',
      maxNativeZoom: 19,
    );
  }

  void _showDetail(BuildContext context, MapMarker marker) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: AppCard(
          icon: _iconFor(marker.type),
          title: marker.name,
          subtitle: marker.type.isEmpty ? null : marker.type,
          padding: false,
          trailing: marker.hasCoordinates
              ? AppStatusBadge(
                  label: marker.sector.isEmpty ? 'lokasi' : marker.sector,
                  color: _colorFor(marker.type),
                  icon: Icons.place,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marker.kecamatan != null && marker.kecamatan!.isNotEmpty)
                  AppInfoRow(label: 'Kecamatan', value: marker.kecamatan!),
                if (marker.kelurahan != null && marker.kelurahan!.isNotEmpty)
                  AppInfoRow(label: 'Kelurahan', value: marker.kelurahan!),
                if (marker.status != null && marker.status!.isNotEmpty)
                  AppInfoRow(label: 'Status', value: marker.status!),
                if (marker.hasCoordinates)
                  AppInfoRow(
                    label: 'Koordinat',
                    value: '${marker.latitude!.toStringAsFixed(5)}, '
                        '${marker.longitude!.toStringAsFixed(5)}',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _sectorColor(String sector) {
    return _sectors.firstWhere((s) => s.key == sector).color;
  }

  Color _chip(ThemeData t, ({String key, String label, IconData? icon, Color color}) sector) {
    return sector.key.isEmpty ? t.colorScheme.onSurface : sector.color;
  }

  Color _colorFor(String type) {
    return switch (type) {
      'school' => AppColors.dataPendidikan,
      'health_facility' => AppColors.dataKesehatan,
      'polsek' => AppColors.dataKeamanan,
      'poskamling' => AppColors.dataKeamanan,
      'market' => AppColors.dataFasilitas,
      'tipkamtikmas' => AppColors.dataKeamanan,
      _ => Colors.blueGrey,
    };
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'school' => Icons.school_outlined,
      'health_facility' => Icons.local_hospital_outlined,
      'polsek' => Icons.local_police_outlined,
      'poskamling' => Icons.visibility_outlined,
      'market' => Icons.storefront_outlined,
      'tipkamtikmas' => Icons.report_outlined,
      _ => Icons.place_outlined,
    };
  }
}

class _MapError extends StatelessWidget {
  const _MapError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing map pin for an active SOS incident, colored by its category.
class _IncidentPin extends StatelessWidget {
  const _IncidentPin({required this.incident});

  final SosAlert incident;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: incident.categoryColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: incident.categoryColor.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          incident.categoryIcon,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
