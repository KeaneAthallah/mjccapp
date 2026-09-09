import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/audit_provider.dart';
import '../../widgets/app_status_badge.dart';
import '../../widgets/async_view.dart';

/// Admin audit log screen.
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final _searchController = TextEditingController();
  bool _moreCalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditProvider>().loadFirst();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => provider.setSearch(v),
              decoration: const InputDecoration(
                hintText: 'Cari log...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: provider,
              builder: (context, _) {
                if (provider.loading) return const AsyncLoadingView();
                if (provider.error != null) {
                  return AsyncErrorView(
                    message: provider.error!,
                    onRetry: provider.loadFirst,
                  );
                }
                if (provider.items.isEmpty) {
                  return const AsyncEmptyView(message: 'Belum ada log.');
                }
                _moreCalled = false;
                return RefreshIndicator(
                  onRefresh: provider.loadFirst,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.items.length + 1,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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
                      final log = provider.items[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.emerald500,
                                AppColors.blue600,
                              ],
                            ),
                          ),
                          child: Text(
                            (log.action ?? '?').isEmpty
                                ? '?'
                                : log.action![0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          '${log.action ?? ''} ${log.resourceType ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            if (log.userName.isNotEmpty) log.userName,
                            if (log.resourceId != null) 'ID ${log.resourceId}',
                            _formatDate(log.createdAt),
                          ].join(' • '),
                        ),
                        trailing: log.description != null
                            ? IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => _showDetail(context, log),
                              )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, dynamic log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${log.action ?? ''} ${log.resourceType ?? ''}',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppStatusBadge(
                  label: log.action?.toString() ?? 'INFO',
                  tone: _actionTone(log.action?.toString()),
                ),
                const SizedBox(height: AppSpacing.md),
                if (log.userName.isNotEmpty) _row('Pengguna', log.userName),
                if (log.resourceId != null) _row('ID', '${log.resourceId}'),
                if (log.description != null &&
                    (log.description as String).isNotEmpty)
                  _row('Keterangan', log.description as String),
                _row('Waktu', _formatDate(log.createdAt)),
                if (log.ipAddress != null &&
                    (log.ipAddress as String).isNotEmpty)
                  _row('IP', log.ipAddress as String),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BadgeTone _actionTone(String? action) {
    final a = action?.toLowerCase() ?? '';
    if (a.contains('hapus') || a.contains('delete')) return BadgeTone.red;
    if (a.contains('buat') || a.contains('create') || a.contains('tambah')) {
      return BadgeTone.green;
    }
    if (a.contains('ubah') || a.contains('update') || a.contains('edit')) {
      return BadgeTone.blue;
    }
    return BadgeTone.gray;
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
}
