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
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Peta MJCC')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sector in _sectors)
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sector.icon != null) ...[
                          Icon(sector.icon, size: 16, color: _chip(t, sector)),
                          const SizedBox(width: 4),
                        ],
                        Text(sector.label),
                      ],
                    ),
                    selected: map.sector == sector.key,
                    selectedColor: sector.color,
                    labelStyle: TextStyle(
                      color: _chip(t, sector),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (_) => map.setSector(sector.key),
                  ),
              ],
            ),
          ),
          if (map.sector.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in _types[map.sector]!)
                    ChoiceChip(
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
                      onSelected: (_) => map.setType(type.$1),
                    ),
                ],
              ),
            ),
          if (master.kecamatans != null && master.kecamatans!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: DropdownButtonFormField<int>(
                initialValue: map.kecamatanId ?? -1,
                decoration: const InputDecoration(
                  labelText: 'Kecamatan',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text('Semua Kecamatan'),
                  ),
                  for (final k in master.kecamatans!)
                    DropdownMenuItem<int>(
                      value: k.id,
                      child: Text(k.name ?? '-'),
                    ),
                ],
                onChanged: (v) => map.setKecamatan(v == -1 ? null : v),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(child: _buildMap(map)),
        ],
      ),
    );
  }

  Widget _buildMap(MapProvider map) {
    if (map.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (map.error != null) {
      return _MapError(message: map.error!, onRetry: map.load);
    }
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

    if (markers.isEmpty && incidents.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: options(),
              children: [_tileLayer()],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Tidak ada lokasi untuk filter ini.'),
          ),
        ],
      );
    }

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
