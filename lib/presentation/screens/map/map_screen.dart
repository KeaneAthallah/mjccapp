import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../data/models/map_data.dart';
import '../../../data/models/sos_alert.dart';
import '../../providers/map_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/sos_provider.dart';
import '../sos/sos_detail_screen.dart';

/// Map screen: interactive OpenStreetMap with sector/type/kecamatan filters
/// plus a live overlay of open SOS emergency incidents.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  static const _sectors = [
    ('', 'Semua Sektor', null),
    ('pendidikan', 'Pendidikan', Icons.school_outlined),
    ('kesehatan', 'Kesehatan', Icons.medical_services_outlined),
    ('ketertiban', 'Ketertiban', Icons.local_police_outlined),
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
                        if (sector.$3 != null) ...[
                          Icon(sector.$3, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Text(sector.$2),
                      ],
                    ),
                    selected: map.sector == sector.$1,
                    onSelected: (_) => map.setSector(sector.$1),
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(marker.name, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (marker.sector.isNotEmpty) _infoRow('Sektor', marker.sector),
            if (marker.kecamatan != null)
              _infoRow('Kecamatan', marker.kecamatan!),
            if (marker.kelurahan != null)
              _infoRow('Kelurahan', marker.kelurahan!),
            if (marker.status != null) _infoRow('Status', marker.status!),
            if (marker.hasCoordinates)
              _infoRow(
                'Koordinat',
                '${marker.latitude!.toStringAsFixed(5)}, '
                '${marker.longitude!.toStringAsFixed(5)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _colorFor(String type) {
    return switch (type) {
      'school' => const Color(0xFF1565C0),
      'health_facility' => const Color(0xFFE53935),
      'polsek' => const Color(0xFF2E7D32),
      'poskamling' => const Color(0xFFF57C00),
      'market' => const Color(0xFF6A1B9A),
      'tipkamtikmas' => const Color(0xFF00838F),
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
