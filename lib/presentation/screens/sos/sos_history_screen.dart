import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sos_alert.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/async_view.dart';
import 'sos_detail_screen.dart';

/// SOS history/inbox. Operators see every alert (open first); regular users
/// only see their own.
class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  final ScrollController _scroll = ScrollController();
  Timer? _pollTimer;
  bool _moreCalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SosProvider>().loadHistory();
    });
    // Keep the inbox fresh without reloading the page. Skip while the user
    // is scrolled down so pagination is not interrupted.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!_scroll.hasClients || _scroll.offset < 1) {
          context.read<SosProvider>().loadHistory(silent: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SosProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(auth.canWrite ? 'Inbox SOS' : 'Riwayat SOS Saya'),
      ),
      body: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          if (provider.loading) return const AsyncLoadingView();
          if (provider.error != null && provider.items.isEmpty) {
            return AsyncErrorView(
              message: provider.error!,
              onRetry: provider.loadHistory,
            );
          }
          if (provider.items.isEmpty) {
            return const AsyncEmptyView(message: 'Belum ada data SOS.');
          }
          _moreCalled = false;
          return RefreshIndicator(
            onRefresh: provider.loadHistory,
            child: ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.items.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.items.length) {
                  if (provider.loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.hasMore && !_moreCalled) {
                    _moreCalled = true;
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => provider.loadMore(),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final alert = provider.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _historyCard(context, alert, auth.canWrite),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _historyCard(BuildContext context, SosAlert alert, bool canWrite) {
    final colors = Theme.of(context).colorScheme;
    final isOpen = alert.isOpen;
    return Material(
      color: colors.surface,
      elevation: isOpen ? 2 : 0.5,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      shadowColor: isOpen ? AppColors.red600.withValues(alpha: 0.3) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SosDetailScreen(alertId: alert.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: isOpen
                ? Border.all(color: AppColors.red200, width: 1.2)
                : Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: alert.categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm - 2),
                ),
                child: Icon(
                  alert.categoryIcon,
                  size: 22,
                  color: alert.categoryColor,
                ),
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
                            'SOS #${alert.id}'
                            '${alert.userName != null && canWrite ? ' · ${alert.userName}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        AppStatusBadge(
                          label: alert.statusLabel,
                          tone: _toneFor(alert.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${alert.categoryLabel} · ${_formatDate(alert.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (alert.message != null && alert.message!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alert.message!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }

  BadgeTone _toneFor(String status) => switch (status) {
        SosAlert.statusActive => BadgeTone.red,
        SosAlert.statusAcknowledged => BadgeTone.amber,
        SosAlert.statusResponding => BadgeTone.blue,
        SosAlert.statusResolved => BadgeTone.green,
        SosAlert.statusCancelled => BadgeTone.gray,
        _ => BadgeTone.gray,
      };
}