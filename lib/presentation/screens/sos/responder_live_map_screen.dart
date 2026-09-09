import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/responder_location.dart';
import '../../../data/models/sos_alert.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/async_view.dart';

/// Live map for the requester: shows where the assigned petugas is right now
/// while their SOS is active. Polls the responder locations every few seconds.
class ResponderLiveMapScreen extends StatefulWidget {
  const ResponderLiveMapScreen({super.key, required this.alert});

  final SosAlert alert;

  @override
  State<ResponderLiveMapScreen> createState() => _ResponderLiveMapScreenState();
}

class _ResponderLiveMapScreenState extends State<ResponderLiveMapScreen> {
  Timer? _timer;
  List<ResponderLocation> _locations = const [];
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(initial: true);
      _timer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refresh(),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (initial) {
      setState(() => _initialLoading = true);
    }
    final locations = await context
        .read<SosProvider>()
        .loadResponderLocations(widget.alert.id, silent: true);
    if (!mounted) return;
    setState(() {
      _locations = locations;
      _initialLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final colors = AppThemeColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Petugas'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          _statusHeader(alert, colors),
          Expanded(
            child: _initialLoading
                ? const AsyncLoadingView()
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(alert.latitude, alert.longitude),
                      initialZoom: 13,
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
                      if (_locations.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            for (final loc in _locations)
                              Marker(
                                point: LatLng(loc.latitude, loc.longitude),
                                width: 44,
                                height: 44,
                                child: _ResponderMarker(location: loc),
                              ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(alert.latitude, alert.longitude),
                            width: 40,
                            height: 40,
                            child: Icon(
                              alert.categoryIcon,
                              size: 36,
                              color: alert.categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          _bottomBar(alert, colors),
        ],
      ),
    );
  }

  Widget _statusHeader(SosAlert alert, AppThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
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
          const Icon(Icons.location_on, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          const Text(
            'Live',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(SosAlert alert, AppThemeColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: _locations.isEmpty
          ? Text(
              'Lokasi petugas belum tersedia. '
              'Petugas akan terlihat di peta saat mulai bergerak.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            )
          : _locationList(),
    );
  }

  Widget _locationList() {
    final colors = AppThemeColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final loc in _locations) ...[
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    AppTheme.radiusSm - 2,
                  ),
                ),
                child: const Icon(
                  Icons.emergency_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.userName ?? 'Petugas',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (loc.responderTypeLabel != null)
                      Text(
                        loc.responderTypeLabel!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.my_location,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Terkini',
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Blue pulsing marker representing a responder's live position.
class _ResponderMarker extends StatelessWidget {
  const _ResponderMarker({required this.location});

  final ResponderLocation location;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.blue700,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            location.userName ?? 'Petugas',
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(
          Icons.local_police,
          size: 34,
          color: AppColors.blue600,
        ),
      ],
    );
  }
}