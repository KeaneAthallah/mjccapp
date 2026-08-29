import 'package:flutter/foundation.dart';

import '../../core/network/paginated.dart';
import '../../core/utils/error_messages.dart';
import '../../data/repositories/resource_api.dart';

/// Generic state holder for a paginated, searchable resource list.
abstract class ListProvider<T> extends ChangeNotifier {
  ListProvider(this.api);

  final ResourceApi<T> api;

  List<T> _items = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _search = '';
  Map<String, dynamic> _filters = const {};

  List<T> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _page < _lastPage;
  bool get isEmpty => _items.isEmpty && !_loading && _error == null;
  String get search => _search;

  Map<String, dynamic> get filters => _filters;

  /// Applies server-side search (debounced by the caller) and reloads.
  void setSearch(String value) {
    _search = value.trim();
    loadFirst();
  }

  /// Sets a filter value that was previously configured.
  void applyFilter(String key, dynamic value) {
    final next = Map<String, dynamic>.from(_filters);
    if (value == null || (value is String && value.isEmpty)) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    _filters = Map.unmodifiable(next);
    loadFirst();
  }

  /// Loads the first page (fresh query).
  Future<void> loadFirst() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await fetch(page: 1);
      _items = List.of(result.items);
      _page = result.currentPage;
      _lastPage = result.lastPage;
    } catch (e) {
      _error = _message(e);
      if (_search.isNotEmpty) _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Appends the next page when available.
  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || _loading) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await fetch(page: _page + 1);
      _items = [..._items, ...result.items];
      _page = result.currentPage;
      _lastPage = result.lastPage;
    } catch (e) {
      _error = _message(e);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Soft-deletes an item and removes it from the local list on success.
  Future<void> delete(T item, int id) async {
    await api.destroy(id);
    _items = _items.where((i) => i != item).toList();
    notifyListeners();
  }

  /// Provided by subclasses so each screen knows how to query the API.
  Future<Paginated<T>> fetch({required int page});

  String _message(Object e) => ErrorMessages.of(e);
}
