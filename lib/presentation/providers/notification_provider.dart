import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/utils/error_messages.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo = NotificationRepository();

  List<AppNotification> _items = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  Timer? _pollTimer;

  /// Local notification ids we have already surfaced, so a given SOS is not
  /// re-shown (with sound) on every poll.
  final Set<int> _notified = {};

  List<AppNotification> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _page < _lastPage;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  void startPolling() {
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => load(silent: true),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final result = await _repo.index(page: 1, perPage: 20);
      _items = List.of(result.items);
      _page = result.currentPage;
      _lastPage = result.lastPage;
      _surfaceNewSosNotifications();
    } catch (e) {
      if (!silent) _error = ErrorMessages.of(e);
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
      final result = await _repo.index(page: _page + 1, perPage: 20);
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

  Future<void> markRead(int id) async {
    try {
      await _repo.markRead(id);
      final index = _items.indexWhere((n) => n.id == id);
      if (index >= 0) {
        final old = _items[index];
        _items = [
          ..._items.sublist(0, index),
          AppNotification(
            id: old.id,
            userId: old.userId,
            title: old.title,
            body: old.body,
            type: old.type,
            data: old.data,
            readAt: DateTime.now(),
            createdAt: old.createdAt,
          ),
          ..._items.sublist(index + 1),
        ];
        notifyListeners();
      }
    } catch (e) {
      _error = ErrorMessages.of(e);
    }
  }

  /// Shows a sound/vibrating local notification for every new, unread SOS
  /// notification (exactly once). Best-effort: a device without permission
  /// simply skips it.
  void _surfaceNewSosNotifications() {
    for (final n in _items) {
      if (!n.isSos || n.isRead || _notified.contains(n.id)) continue;
      _notified.add(n.id);
      var sosId = n.id;
      if (n.data is Map<String, dynamic> && n.data!['sos_alert_id'] != null) {
        final raw = n.data!['sos_alert_id'];
        if (raw is num) sosId = raw.toInt();
      } else if (n.data is Map<String, dynamic> &&
          n.data!['sos_id'] != null) {
        final raw = n.data!['sos_id'];
        if (raw is num) sosId = raw.toInt();
      }
      NotificationService.instance.showEmergencySos(
        id: sosId,
        categoryLabel: _categoryLabel(n),
        title: n.title,
        body: n.body,
      );
    }
  }

  String _categoryLabel(AppNotification n) {
    if (n.data is! Map<String, dynamic>) return 'SOS';
    final category = n.data!['category'] as String?;
    return switch (category) {
      'medical' => 'Medis',
      'fire' => 'Pemadam Kebakaran',
      'police' => 'Polisi',
      _ => 'SOS',
    };
  }
}
