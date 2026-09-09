import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/async_view.dart';
import '../sos/sos_detail_screen.dart';

/// Notifications list screen.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  Future<void> _openNotification(AppNotification n) async {
    final provider = context.read<NotificationProvider>();
    if (!n.isRead) await provider.markRead(n.id);
    if (!mounted) return;
    if (n.isSos) {
      final data = n.data;
      final sosAlertId = data is Map<String, dynamic>
          ? (data['sos_alert_id'] as num?) ?? (data['sos_id'] as num?)
          : null;
      final sosId = sosAlertId?.toInt();
      if (sosId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SosDetailScreen(alertId: sosId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: provider.loading ? null : () => provider.load(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          if (provider.loading && provider.items.isEmpty) {
            return const AsyncLoadingView();
          }
          if (provider.error != null && provider.items.isEmpty) {
            return AsyncErrorView(
              message: provider.error!,
              onRetry: provider.load,
            );
          }
          if (provider.items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Belum ada notifikasi',
              description: 'Notifikasi baru akan muncul di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.items.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                if (index == provider.items.length) {
                  if (provider.loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.hasMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.read<NotificationProvider>().loadMore();
                    });
                  }
                  return const SizedBox.shrink();
                }
                final n = provider.items[index];
                return _NotificationTile(
                  notification: n,
                  onTap: () => _openNotification(n),
                  timeLabel: _relativeTime(n.createdAt),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.timeLabel,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isSos = notification.isSos;
    final icon = isSos
        ? Icons.emergency_rounded
        : Icons.info_outline;
    final color = isSos ? AppColors.sosMedical : AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm - 2),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
