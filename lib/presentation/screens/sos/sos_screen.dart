import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sos_alert.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_info_row.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/sos/sos_status_tracker.dart';
import 'sos_create_screen.dart';
import 'sos_detail_screen.dart';
import 'sos_history_screen.dart';
import 'responder_live_map_screen.dart';

/// SOS emergency screen: sends a location-based SOS and tracks the user's
/// own open alert through the operator workflow.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  SosProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<SosProvider>();
      _provider!.refreshMyOpen().then((_) {
        if (_provider!.hasOpen) _provider!.startPolling();
      });
      _provider!.loadActiveIncidents(silent: true);
    });
  }

  @override
  void dispose() {
    _provider?.stopPolling();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SosCreateScreen()),
    );
    if (created == true && mounted) {
      await context.read<SosProvider>().refreshMyOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SosProvider>();
    final auth = context.watch<AuthProvider>();
    final isResponder = auth.user?.isResponder ?? false;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Darurat'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            tooltip: 'Riwayat SOS',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SosHistoryScreen()),
            ),
          ),
          _refreshButton(provider),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshMyOpen,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (provider.hasOpen)
              _ActiveAlertCard(provider: provider, colors: colors)
            else
              _SendSosCard(provider: provider, onSend: _openCreate),
            if (isResponder) ...[
              const SizedBox(height: AppSpacing.sm),
              _ResponderIncidents(provider: provider),
            ],
            if (provider.error != null && !provider.hasOpen)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: AppErrorState(
                  message: provider.error!,
                  onRetry: provider.refreshMyOpen,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _refreshButton(SosProvider provider) {
    return IconButton(
      tooltip: 'Muat ulang',
      icon: const Icon(Icons.refresh),
      onPressed: provider.loading
          ? null
          : () {
              provider.refreshMyOpen();
              if (provider.hasOpen) provider.startPolling();
            },
    );
  }
}

/// Entry card to start the new categorized SOS flow.
class _SendSosCard extends StatelessWidget {
  const _SendSosCard({required this.provider, required this.onSend});

  final SosProvider provider;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          title: 'Bantuan Darurat',
          subtitle: 'Kirim lokasi Anda ke petugas secara instan',
          icon: Icons.sos,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tekan tombol di bawah saat Anda berada dalam keadaan darurat. '
                'Lokasi terkini beserta waktu akan langsung dikirim ke Pusat '
                'Pengendalian dan petugas terdekat.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 132,
                child: ElevatedButton(
                  onPressed: provider.locating ? null : onSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.red600.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.red600.withValues(alpha: 0.5),
                  ),
                  child: provider.locating
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emergency_rounded, size: 40),
                            SizedBox(height: 6),
                            Text(
                              'LAPORKAN DARURAT',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Gunakan hanya untuk keadaan darurat yang sebenarnya',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _InfoRow(),
      ],
    );
  }
}

/// Shown while the user has a live alert: prominent "SOS AKTIF" banner with
/// live status tracker, alert details and actions.
class _ActiveAlertCard extends StatelessWidget {
  const _ActiveAlertCard({required this.provider, required this.colors});

  final SosProvider provider;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final alert = provider.myOpen!;
    final auth = context.read<AuthProvider>();
    final canCancel = alert.isOpen && (alert.isOwner || auth.canWrite);
    final theme = AppThemeColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.red600.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _banner(alert),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SosStatusTracker(alert: alert),
                const SizedBox(height: AppSpacing.md),
                AppInfoRow(
                  label: 'Kategori',
                  value: alert.categoryLabel,
                ),
                AppInfoRow(
                  label: 'Waktu Lapor',
                  value: _formatTime(alert.createdAt),
                ),
                AppInfoRow(
                  label: 'Koordinat',
                  value:
                      '${alert.latitude.toStringAsFixed(5)}, '
                      '${alert.longitude.toStringAsFixed(5)}',
                ),
                if (alert.acceptedByUser != null)
                  AppInfoRow(
                    label: 'Petugas',
                    value: alert.acceptedByUser!,
                  ),
                if (alert.message != null && alert.message!.isNotEmpty) ...[
                  AppInfoRow(label: 'Pesan', value: alert.message!),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (alert.responseMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm - 3),
                    ),
                    child: Text(
                      alert.responseMessage!,
                      style: const TextStyle(
                        color: AppColors.blue800,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (alert.isOpen)
                  AppButton(
                    label: 'LIHAT PETA PETUGAS',
                    icon: Icons.map_outlined,
                    variant: AppButtonVariant.secondary,
                    expanded: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ResponderLiveMapScreen(alert: alert),
                      ),
                    ),
                  ),
                if (canCancel) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    label: 'Batalkan SOS',
                    icon: Icons.cancel_outlined,
                    variant: AppButtonVariant.danger,
                    expanded: true,
                    onPressed: () => _confirmCancel(context),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Status diperbarui secara otomatis setiap beberapa detik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(SosAlert alert) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.red700, AppColors.red600],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sos, size: 28, color: AppColors.red600),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOS AKTIF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _liveDot(),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '#${alert.id} · ${alert.categoryLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              alert.statusLabel.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? d) {
    if (d == null) return '-';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} · ${two(d.hour)}:${two(d.minute)} WITA';
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan SOS'),
        content: const Text('Batalkan permintaan SOS ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red600),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<SosProvider>().cancelMySos();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.emerald700 : AppColors.red600,
        content: Text(
          success ? 'SOS telah dibatalkan.' : 'Gagal membatalkan. Coba lagi.',
        ),
      ),
    );
  }
}

/// Active incidents list for responder users.
class _ResponderIncidents extends StatelessWidget {
  const _ResponderIncidents({required this.provider});

  final SosProvider provider;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final incidents = provider.activeIncidents.where((a) => a.isOpen).toList();

    return AppCard(
      title: 'Kejadian Aktif',
      subtitle: 'Kejadian darurat yang membutuhkan tindakan',
      icon: Icons.emergency_outlined,
      trailing: AppStatusBadge(
        label: '${incidents.length} aktif',
        tone: incidents.isEmpty ? BadgeTone.green : BadgeTone.red,
      ),
      child: provider.loadingActive
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          : incidents.isEmpty
              ? Text(
                  'Tidak ada kejadian aktif saat ini.',
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                )
              : Column(
                  children: [
                    for (final incident in incidents)
                      InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SosDetailScreen(alertId: incident.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: incident.categoryColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm - 2,
                                  ),
                                ),
                                child: Icon(
                                  incident.categoryIcon,
                                  size: 20,
                                  color: incident.categoryColor,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SOS #${incident.id}'
                                      '${incident.userName != null ? ' · ${incident.userName}' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      incident.statusLabel,
                                      style: TextStyle(
                                        color: colors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppStatusBadge(
                                label: incident.statusLabel,
                                tone: _toneFor(incident.status),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  BadgeTone _toneFor(String status) => switch (status) {
        SosAlert.statusActive => BadgeTone.red,
        SosAlert.statusAcknowledged => BadgeTone.amber,
        SosAlert.statusResponding => BadgeTone.blue,
        SosAlert.statusOnTheWay => BadgeTone.blue,
        SosAlert.statusArrived => BadgeTone.teal,
        SosAlert.statusResolved => BadgeTone.green,
        SosAlert.statusCancelled => BadgeTone.gray,
        _ => BadgeTone.gray,
      };
}

class _InfoRow extends StatelessWidget {
  List<String> get _points => const [
        'Lokasi GPS dikirim otomatis',
        'Petugas mendapat notifikasi real-time',
        'Status dapat dipantau dari aplikasi',
      ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      title: 'Cara Kerja',
      icon: Icons.timeline_outlined,
      child: Column(
        children: [
          for (final point in _points)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 18, color: AppColors.emerald600),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(fontSize: 13, color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
