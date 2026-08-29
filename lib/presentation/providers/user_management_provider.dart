import 'package:flutter/foundation.dart';

import '../../core/utils/error_messages.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/repositories.dart';
import '../../data/repositories/user_management_repository.dart';

/// State for the admin users management screen.
class UserManagementProvider extends ChangeNotifier {
  final UserManagementRepository _repo = Repositories.instance.userManagement;

  List<UserModel> _items = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _search = '';

  List<UserModel> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _page < _lastPage;
  String get search => _search;

  void setSearch(String value) {
    _search = value.trim();
    loadFirst();
  }

  Future<void> loadFirst() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.index(page: 1, search: _search);
      _items = List.of(result.items);
      _page = result.currentPage;
      _lastPage = result.lastPage;
    } catch (e) {
      _error = ErrorMessages.of(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore || _loading) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _repo.index(page: _page + 1, search: _search);
      _items = [..._items, ...result.items];
      _page = result.currentPage;
      _lastPage = result.lastPage;
    } catch (e) {
      _error = ErrorMessages.of(e);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    await _repo.destroy(id);
    _items = _items.where((u) => u.id != id).toList();
    notifyListeners();
  }
}
