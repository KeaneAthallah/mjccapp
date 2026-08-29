import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
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
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.items.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
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
                return ListTile(
                  leading: _avatar(alert),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SOS #${alert.id}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      AppStatusBadge(
                        label: alert.statusLabel,
                        tone: _toneFor(alert.status),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (auth.canWrite && alert.userName != null)
                          '${alert.userName} •',
                        _formatDate(alert.createdAt),
                      ].join(' '),
                    ),
                  ),
                  isThreeLine: alert.message != null && alert.message!.isNotEmpty,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SosDetailScreen(alertId: alert.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _avatar(SosAlert alert) {
    final color = alert.isActive ? AppColors.red600 : AppColors.emerald600;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(
        alert.isActive ? Icons.sos : Icons.emergency_outlined,
        size: 20,
        color: color,
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