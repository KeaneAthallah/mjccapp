import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/location/location_service.dart';
import '../../core/utils/error_messages.dart';
import '../../data/models/sos_alert.dart';
import '../../data/repositories/repositories.dart';
import '../../data/repositories/sos_repository.dart';

/// State for the SOS module: sending location-based alerts, tracking the
/// user's own open alert, and browsing the inbox/history.
class SosProvider extends ChangeNotifier {
  final SosRepository _repo = Repositories.instance.sos;
  final LocationService _location = const LocationService();

  static const Duration _pollInterval = Duration(seconds: 15);

  SosAlert? _myOpen;
  List<SosAlert> _items = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loading = false;
  bool _loadingMore = false;
  bool _locating = false;
  String? _error;
  Timer? _pollTimer;
  int _changeCounter = 0;

  SosAlert? get myOpen => _myOpen;
  bool get hasOpen => _myOpen != null;
  List<SosAlert> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get locating => _locating;
  String? get error => _error;
  bool get hasMore => _page < _lastPage;

  /// Increments whenever `myOpen` changes, so the UI can animate on status
  /// transitions while polling.
  int get changeCounter => _changeCounter;

  /// Starts background polling for status changes to the user's open alert.
  /// No-op if already active; safe when there is no open alert yet.
  void startPolling() {
    _pollTimer ??= Timer.periodic(_pollInterval, (_) => refreshMyOpen());
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

  /// Fetches the user's own open alert (backed by `GET /sos/my-open`).
  Future<void> refreshMyOpen({bool silent = false}) async {
    if (_locating && silent) return;
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final alert = await _repo.myOpen();
      if (alert?.id != _myOpen?.id || alert?.status != _myOpen?.status) {
        _changeCounter++;
      }
      _myOpen = alert;
      if (_myOpen == null) stopPolling();
    } catch (e) {
      if (!silent) _error = ErrorMessages.of(e);
    } finally {
      if (!silent) {
        _loading = false;
        notifyListeners();
      } else if (_myOpen != null) {
        notifyListeners();
      }
    }
  }

  /// Locates the device then sends the SOS. Returns `true` on success.
  Future<bool> sendSos({String? message}) async {
    _locating = true;
    _error = null;
    notifyListeners();
    try {
      final fix = await _location.currentPosition();
      final alert = await _repo.create(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracy: fix.accuracy,
        message: message,
      );
      _myOpen = alert;
      _changeCounter++;
      startPolling();
      return true;
    } on LocationFailure catch (e) {
      _error = e.message;
      return false;
    } on Exception catch (e) {
      _error = ErrorMessages.of(e);
      return false;
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  Future<bool> cancelMySos() async {
    final alert = _myOpen;
    if (alert == null) return true;
    try {
      final cancelled = await _repo.cancel(alert.id);
      _myOpen = cancelled;
      _changeCounter++;
      stopPolling();
      return true;
    } catch (e) {
      _error = ErrorMessages.of(e);
      notifyListeners();
      return false;
    }
  }

  /// Fetches a single alert, keeping it in sync with the local caches.
  Future<SosAlert> show(int id) async {
    final alert = await _repo.show(id);
    _replaceItem(alert);
    if (_myOpen?.id == id) {
      _myOpen = alert;
      if (!alert.isOpen) stopPolling();
    }
    return alert;
  }

  /// Fetches the first page of the inbox. With [silent] the loading state is
  /// left untouched so background polling does not flash the spinner.
  Future<void> loadHistory({bool silent = false}) async {
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
    } catch (e) {
      if (!silent) _error = ErrorMessages.of(e);
    } finally {
      if (!silent) {
        _loading = false;
      }
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

  /// Optimistically applies a transition locally (acknowledge/respond/resolve)
  /// so the UI stays snappy; the source of truth is always the server.
  Future<void> transition(
    SosAlert alert,
    SosTransition transition, {
    String? message,
  }) async {
    try {
      SosAlert updated;
      switch (transition) {
        case SosTransition.acknowledge:
          updated = await _repo.acknowledge(alert.id, message: message);
        case SosTransition.respond:
          updated = await _repo.respond(alert.id, message: message);
        case SosTransition.resolve:
          updated = await _repo.resolve(alert.id, message: message);
      }
      _replaceItem(updated);
      if (_myOpen?.id == updated.id) {
        _myOpen = updated;
        _changeCounter++;
        if (!updated.isOpen) stopPolling();
      }
    } catch (e) {
      _error = ErrorMessages.of(e);
    } finally {
      notifyListeners();
    }
  }

  void _replaceItem(SosAlert updated) {
    final index = _items.indexWhere((a) => a.id == updated.id);
    if (index >= 0) {
      final list = List.of(_items);
      list[index] = updated;
      _items = list;
    }
  }
}

enum SosTransition { acknowledge, respond, resolve }