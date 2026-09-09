import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/location/live_location_service.dart';
import '../../../core/network/routing_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sos_alert.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_status_badge.dart';

/// Full-screen responder journey for an accepted SOS:
/// live GPS + real OSRM road route + distance + ETA + status buttons.
class ResponderJourneyScreen extends StatefulWidget {
  const ResponderJourneyScreen({super.key, required this.alert});

  final SosAlert alert;

  @override
  State<ResponderJourneyScreen> createState() => _ResponderJourneyScreenState();
}

class _ResponderJourneyScreenState extends State<ResponderJourneyScreen> {
  final MapController _mapController = MapController();
  final LiveLocationTracker _tracker = LiveLocationTracker();
  final RoutingService _routing = const RoutingService();

  SosAlert? _alert;
  LiveLocationFix? _myLocation;
  RouteResult? _route;
  bool _tracking = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _alert = widget.alert;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTracking();
      _refreshAlert();
    });
  }

  @override
  void dispose() {
    _tracker.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    setState(() => _tracking = true);
    await _tracker.start(
      onFix: (fix) {
        if (mounted) {
          setState(() => _myLocation = fix);
          _maybeRoute();
        }
      },
      onUpload: (fix) async {
        final alert = _alert;
        if (alert == null) return;
        await context.read<SosProvider>().updateResponderLocation(
          sosId: alert.id,
          latitude: fix.latitude,
          longitude: fix.longitude,
        );
      },
    );
  }

  void _maybeRoute() {
    final my = _myLocation;
    final alert = _alert;
    if (my == null || alert == null) return;
    _fetchRoute(
      LatLng(my.latitude, my.longitude),
      LatLng(alert.latitude, alert.longitude),
    );
  }

  // Avoids requesting a new OSRM route on every GPS tick: only refetch when
  // we moved more than ~80 m from the last route origin, or when there is no
  // route yet. This keeps API calls low while the responder travels.
  LatLng? _lastRouteOrigin;

  Future<void> _fetchRoute(LatLng origin, LatLng destination) async {
    final last = _lastRouteOrigin;
    if (last != null && _route != null) {
      final moved = _distanceMeters(last, origin);
      if (moved < 80) return;
    }
    final result = await _routing.route(origin: origin, destination: destination);
    if (!mounted) return;
    setState(() {
      if (result != null) {
        _route = result;
        _lastRouteOrigin = origin;
      }
    });
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    double rad(double deg) => deg * math.pi / 180.0;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final h = sinLat * sinLat +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            sinLng *
            sinLng;
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  Future<void> _refreshAlert() async {
    try {
      final alert = await context.read<SosProvider>().show(_alert!.id);
      if (mounted) setState(() => _alert = alert);
    } catch (_) {
      // Ignore refresh errors; the user can pull to retry via the buttons.
    }
  }

  Future<void> _transition(String action) async {
    final alert = _alert;
    if (alert == null) return;
    final provider = context.read<SosProvider>();
    setState(() => _busy = true);
    bool ok;
    switch (action) {
      case 'ontheway':
        ok = await provider.onTheWaySos(alert.id);
      case 'arrived':
        ok = await provider.arrivedSos(alert.id);
      case 'resolve':
        ok = await provider.resolveSos(alert.id);
      default:
        ok = false;
    }
    await _refreshAlert();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status diperbarui.')),
      );
      if (action == 'resolve' && mounted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal memperbarui status.'),
          backgroundColor: AppColors.red600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = _alert!;
    final colors = AppThemeColors.of(context);
    final my = _myLocation;
    final route = _route;

    final markers = <Marker>[
      if (my != null)
        Marker(
          point: LatLng(my.latitude, my.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, size: 40, color: AppColors.secondary),
        ),
      Marker(
        point: LatLng(alert.latitude, alert.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.sos, size: 40, color: AppColors.red600),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Perjalanan • ${alert.categoryLabel}'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _statusBar(alert, colors),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(alert.latitude, alert.longitude),
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'id.go.morowali.mjcc',
                  maxNativeZoom: 19,
                ),
                if (route != null && route.points.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.points,
                        strokeWidth: 5,
                        color: AppColors.secondary,
                        borderStrokeWidth: 1.5,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          _actionBar(alert, my, route, colors),
        ],
      ),
    );
  }

  Widget _statusBar(SosAlert alert, AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.cardBorder)),
      ),
      child: Row(
        children: [
          AppStatusBadge(
            label: alert.statusLabel,
            color: alert.categoryColor,
            icon: alert.categoryIcon,
          ),
          const Spacer(),
          if (_myLocation != null)
            Row(
              children: [
                Icon(
                  _tracking ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: _tracking ? AppColors.emerald600 : AppColors.gray400,
                ),
                const SizedBox(width: 4),
                Text(
                  _tracking ? 'Lokasi aktif' : 'Lokasi mati',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionBar(
    SosAlert alert,
    LiveLocationFix? my,
    RouteResult? route,
    AppThemeColors colors,
  ) {
    final distance = (my != null)
        ? my.distanceTo(alert.latitude, alert.longitude)
        : null;
    final showJourneyButton =
        alert.status == SosAlert.statusAccepted &&
            (_myLocation != null);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metric(
                'Jarak',
                route != null
                    ? '${route.distanceKm.toStringAsFixed(1)} km'
                    : (distance != null
                        ? '${(distance / 1000).toStringAsFixed(1)} km'
                        : '—'),
                Icons.route_outlined,
              ),
              _metric(
                'Estimasi',
                route != null ? route.durationLabel : '—',
                Icons.schedule_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_tracking &&
              alert.status != SosAlert.statusResolved &&
              alert.status != SosAlert.statusCancelled) ...[
            if (showJourneyButton ||
                alert.status == SosAlert.statusAccepted)
              AppButton(
                label: 'MULAI PERJALANAN',
                icon: Icons.play_arrow,
                variant: AppButtonVariant.secondary,
                expanded: true,
                loading: _busy,
                onPressed: _busy
                    ? null
                    : () => _transition('ontheway'),
              ),
            if (alert.status == SosAlert.statusOnTheWay ||
                alert.status == SosAlert.statusArrived)
              AppButton(
                label: 'SUDAH TIBA',
                icon: Icons.place_outlined,
                variant: AppButtonVariant.primary,
                expanded: true,
                loading: _busy,
                onPressed: _busy ? null : () => _transition('arrived'),
              ),
            if (alert.status == SosAlert.statusArrived)
              const SizedBox(height: AppSpacing.xs),
            if (alert.status == SosAlert.statusArrived)
              AppButton(
                label: 'SELESAIKAN',
                icon: Icons.check_circle_outline,
                variant: AppButtonVariant.danger,
                expanded: true,
                loading: _busy,
                onPressed: _busy ? null : () => _transition('resolve'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.gray500),
        ),
      ],
    );
  }
}
