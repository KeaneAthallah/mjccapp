import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sos_alert.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/async_view.dart';
import '../../widgets/sos/constraint_dialog.dart';
import '../../widgets/sos/sos_status_tracker.dart';
import 'responder_journey_screen.dart';

/// Detail view of a single SOS alert with a map and management actions.
class SosDetailScreen extends StatefulWidget {
  const SosDetailScreen({super.key, required this.alertId});

  final int alertId;

  @override
  State<SosDetailScreen> createState() => _SosDetailScreenState();
}

class _SosDetailScreenState extends State<SosDetailScreen> {
  SosAlert? _alert;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    try {
      final alert = await context.read<SosProvider>().show(widget.alertId);
      if (mounted) {
        setState(() {
          _alert = alert;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat detail SOS.';
        });
      }
    }
  }

  Future<void> _transition(SosTransition t) async {
    final alert = _alert;
    if (alert == null) return;
    setState(() => _busy = true);
    await context.read<SosProvider>().transition(alert, t);
    await _refresh();
    if (mounted) {
      setState(() => _busy = false);
      final error = context.read<SosProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Status SOS diperbarui.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SOS #${widget.alertId}')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AsyncLoadingView();
    if (_error != null && _alert == null) {
      return AsyncErrorView(message: _error!, onRetry: _refresh);
    }
    final alert = _alert!;
    final auth = context.watch<AuthProvider>();
    final isManager = auth.canWrite;
    final canManage = isManager;
    final canCancel = alert.isOpen && (alert.isOwner || canManage);
    final isResponder = auth.user?.isResponder ?? false;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            title: 'Status SOS',
            subtitle: _formatDate(alert.createdAt),
            icon: Icons.sos,
            trailing: _CategoryBadge(alert: alert),
            child: SosStatusTracker(alert: alert),
          ),
          if (alert.responseMessage != null)
            AppCard(
              title: 'Pesan dari Petugas',
              icon: Icons.forum_outlined,
              child: Text(alert.responseMessage!),
            ),
          if (alert.constraintReason != null &&
              alert.constraintReason!.isNotEmpty)
            _ConstraintCard(alert: alert),
          if (isResponder && alert.userName != null)
            AppCard(
              title: 'Informasi Responder',
              icon: Icons.emergency_outlined,
              child: Column(
                children: [
                  _row('Petugas', alert.userName ?? '-'),
                  if (alert.acceptedByUser != null)
                    _row('Diambil oleh', alert.acceptedByUser!),
                  if (alert.acceptedAt != null)
                    _row('Waktu diterima', _formatDate(alert.acceptedAt)),
                ],
              ),
            ),
          AppCard(
            title: 'Detail',
            icon: Icons.info_outline,
            child: Column(
              children: [
                _row('Status', alert.statusLabel),
                _row('Kategori', alert.categoryLabel),
                if (alert.userName != null && auth.canWrite)
                  _row('Pelapor', alert.userName!),
                _row(
                  'Koordinat',
                  '${alert.latitude.toStringAsFixed(5)}, '
                  '${alert.longitude.toStringAsFixed(5)}',
                ),
                if (alert.accuracy != null)
                  _row('Akurasi', '${alert.accuracy!.round()} m'),
                if (alert.message != null && alert.message!.isNotEmpty)
                  _row('Pesan', alert.message!),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(alert.latitude, alert.longitude),
                  initialZoom: 15,
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
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(alert.latitude, alert.longitude),
                        width: 36,
                        height: 36,
                        child: Icon(
                          alert.categoryIcon,
                          size: 32,
                          color: alert.categoryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isResponder && alert.isOpen)
            AppCard(
              title: alert.status == SosAlert.statusConstrained
                  ? 'Tindakan Responder • Terkendala'
                  : 'Tindakan Responder',
              icon: Icons.handyman_outlined,
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (alert.status == SosAlert.statusAccepted ||
                      alert.status == SosAlert.statusOnTheWay ||
                      alert.status == SosAlert.statusArrived ||
                      alert.status == SosAlert.statusConstrained)
                    AppButton(
                      label: 'Mulai Perjalanan',
                      icon: Icons.navigation_outlined,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ResponderJourneyScreen(alert: alert),
                          ),
                        );
                      },
                    ),
                  if (alert.status == SosAlert.statusActive ||
                      alert.status == SosAlert.statusAccepted ||
                      alert.status == SosAlert.statusAcknowledged)
                    AppButton(
                      label: 'Terima',
                      icon: Icons.inbox_outlined,
                      onPressed: _busy
                          ? null
                          : () =>
                              _setResponderAction(context, alert, 'accept'),
                    ),
                  if (alert.status == SosAlert.statusAccepted ||
                      alert.status == SosAlert.statusOnTheWay ||
                      alert.status == SosAlert.statusConstrained)
                    AppButton(
                      label: 'Petugas Terkendala',
                      icon: Icons.warning_amber_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: _busy
                          ? null
                          : () => _showConstraintDialog(alert),
                    ),
                  if (alert.status == SosAlert.statusAcknowledged ||
                      alert.status == SosAlert.statusOnTheWay ||
                      alert.status == SosAlert.statusActive ||
                      alert.status == SosAlert.statusConstrained)
                    AppButton(
                      label: 'Menuju Lokasi',
                      icon: Icons.directions_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _busy
                          ? null
                          : () =>
                              _setResponderAction(context, alert, 'ontheway'),
                    ),
                  if (alert.status == SosAlert.statusOnTheWay ||
                      alert.status == SosAlert.statusArrived ||
                      alert.status == SosAlert.statusConstrained)
                    AppButton(
                      label: 'Tiba di Lokasi',
                      icon: Icons.place_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _busy
                          ? null
                          : () =>
                              _setResponderAction(context, alert, 'arrived'),
                    ),
                  if (alert.status == SosAlert.statusArrived)
                    AppButton(
                      label: 'Selesaikan',
                      icon: Icons.check_circle_outline,
                      onPressed: _busy
                          ? null
                          : () =>
                              _setResponderAction(context, alert, 'resolve'),
                    ),
                ],
              ),
            ),
          if (canManage || canCancel)
            AppCard(
              title: 'Tindakan',
              icon: Icons.handyman_outlined,
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (canManage && alert.status == SosAlert.statusActive)
                    AppButton(
                      label: 'Terima',
                      icon: Icons.inbox_outlined,
                      onPressed: _busy
                          ? null
                          : () => _transition(SosTransition.acknowledge),
                    ),
                  if (canManage &&
                      (alert.status == SosAlert.statusActive ||
                          alert.status == SosAlert.statusAcknowledged))
                    AppButton(
                      label: 'Menuju Lokasi',
                      icon: Icons.local_police_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: _busy
                          ? null
                          : () => _transition(SosTransition.respond),
                    ),
                  if (canManage &&
                      (alert.status == SosAlert.statusAcknowledged ||
                          alert.status == SosAlert.statusResponding))
                    AppButton(
                      label: 'Selesaikan',
                      icon: Icons.check_circle_outline,
                      onPressed: _busy
                          ? null
                          : () => _transition(SosTransition.resolve),
                    ),
                  if (canCancel)
                    AppButton(
                      label: 'Batalkan',
                      icon: Icons.cancel_outlined,
                      variant: AppButtonVariant.danger,
                      onPressed: _busy ? null : _confirmCancel,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _setResponderAction(
    BuildContext context,
    SosAlert alert,
    String action,
  ) async {
    final provider = context.read<SosProvider>();
    setState(() => _busy = true);
    bool ok;
    switch (action) {
      case 'accept':
        ok = await provider.acceptSos(alert.id);
      case 'ontheway':
        ok = await provider.onTheWaySos(alert.id);
      case 'resolve':
        ok = await provider.resolveSos(alert.id);
      default:
        ok = await provider.arrivedSos(alert.id);
    }
    await _refresh();
    if (!context.mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Gagal memperbarui status. Coba lagi.',
          ),
          backgroundColor: AppColors.red600,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status SOS diperbarui.')),
      );
    }
  }

  Future<void> _showConstraintDialog(SosAlert alert) async {
    final result = await showConstraintDialog(
      context,
      initialType: alert.constraintType ?? SosAlert.constraintDelayed,
      initialReason: alert.constraintReason,
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    final provider = context.read<SosProvider>();
    final ok = await provider.constrainSos(
      alert.id,
      type: result.type,
      reason: result.reason,
    );
    await _refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Kendala petugas telah dilaporkan.'
            : provider.error ?? 'Gagal melaporkan kendala.'),
        backgroundColor: ok ? null : AppColors.red600,
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan SOS'),
        content: const Text('Batalkan permintaan SOS ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red600),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context.read<SosProvider>().cancelMySos();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS telah dibatalkan.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<SosProvider>().error ?? 'Gagal.')),
      );
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

/// Colored category badge shown in the SOS header.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.alert});

  final SosAlert alert;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: alert.categoryLabel,
      color: alert.categoryColor,
      icon: alert.categoryIcon,
    );
  }
}

/// Amber card informing the requester about a petugas constraint (cannot
/// reach / delayed) so they know help may be late.
class _ConstraintCard extends StatelessWidget {
  const _ConstraintCard({required this.alert});

  final SosAlert alert;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Kendala Petugas',
      icon: Icons.warning_amber_rounded,
      child: Column(
        children: [
          if (alert.constraintTypeDisplay != null)
            _row('Jenis kendala', alert.constraintTypeDisplay!),
          _row('Alasan', alert.constraintReason ?? '-'),
          if (alert.constrainedAt != null)
            _row('Waktu laporan', _formatDate(alert.constrainedAt)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
