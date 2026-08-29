import 'dart:async';

import 'package:flutter/material.dart';

import '../providers/list_provider.dart';
import 'async_view.dart';

/// Generic paginated list screen bound to a [ListProvider].
class ListScreen<T> extends StatefulWidget {
  const ListScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.itemBuilder,
    this.canWrite = true,
    this.onCreate,
    this.onEdit,
    this.onDetail,
    this.trailing,
    this.showSearch = true,
    this.fab,
    this.emptyMessage = 'Belum ada data.',
  });

  final String title;
  final ListProvider<T> provider;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Whether to show create/edit/delete controls.
  final bool canWrite;
  final VoidCallback? onCreate;
  final void Function(BuildContext context, T item)? onEdit;
  final void Function(BuildContext context, T item)? onDetail;

  /// Extra trailing widgets shown next to edit/delete actions.
  final Widget? trailing;
  final bool showSearch;
  final Widget? fab;
  final String emptyMessage;

  @override
  State<ListScreen<T>> createState() => _ListScreenState<T>();
}

class _ListScreenState<T> extends State<ListScreen<T>> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.provider.loadFirst();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) widget.provider.setSearch(value);
    });
  }

  Future<void> _confirmDelete(T item, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus data'),
        content: const Text('Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.provider.delete(item, id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus data.')));
      }
    }
  }

  Widget _buildTrailing(T item, int id) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.trailing != null) widget.trailing!,
        if (widget.canWrite && widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => widget.onEdit!(context, item),
          ),
        if (widget.canWrite)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(item, id),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: widget.canWrite && widget.onCreate != null
          ? widget.fab ?? null
          : null,
      body: Column(
        children: [
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.provider.setSearch('');
                            },
                          ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: provider,
              builder: (context, _) {
                if (provider.loading) {
                  return const AsyncLoadingView();
                }
                if (provider.error != null) {
                  return AsyncErrorView(
                    message: provider.error!,
                    onRetry: provider.loadFirst,
                  );
                }
                if (provider.isEmpty) {
                  return AsyncEmptyView(message: widget.emptyMessage);
                }
                return RefreshIndicator(
                  onRefresh: provider.loadFirst,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.items.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == provider.items.length) {
                        return _buildLoader(provider);
                      }
                      final item = provider.items[index];
                      final id = (item as dynamic).id as int;
                      return InkWell(
                        onTap: widget.onDetail == null
                            ? null
                            : () => widget.onDetail!(context, item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: widget.itemBuilder(context, item),
                              ),
                              _buildTrailing(item, id),
                            ],
                          ),
                        ),
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

  Widget _buildLoader(ListProvider<T> provider) {
    if (provider.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadMore();
      });
    }
    return const SizedBox.shrink();
  }
}
