import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// Manages efficient, battery-aware periodic location updates for an active
/// responder journey.
///
/// Strategy:
///  - Sends a fix to the upload callback at most every [minInterval] (5s).
///  - Pauses the upload while the previous upload is still awaiting, so we
///    never pile up concurrent requests.
///
/// The [onFix] callback runs for every stream fix (e.g. to update a map
/// marker in the UI), while [onUpload] is the throttled network upload.
class LiveLocationTracker {
  LiveLocationTracker({this.minInterval = const Duration(seconds: 5)});

  final Duration minInterval;

  StreamSubscription<Position>? _sub;
  int _uploading = 0;
  Future<void> Function(LiveLocationFix fix)? _onUpload;
  DateTime _lastUpload = DateTime.fromMillisecondsSinceEpoch(0);

  /// Starts streaming location fixes, calling [onFix] for local map updates
  /// and [onUpload] for throttled network uploads.
  Future<void> start({
    required void Function(LiveLocationFix fix) onFix,
    required Future<void> Function(LiveLocationFix fix) onUpload,
  }) async {
    _onUpload = onUpload;
    if (_sub != null) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      final fix = LiveLocationFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        heading: position.heading,
        speed: position.speed,
      );
      onFix(fix);
      _maybeUpload(fix);
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _maybeUpload(LiveLocationFix fix) async {
    if (_uploading > 0) return;
    final now = DateTime.now();
    final sinceLast = now.difference(_lastUpload);
    if (sinceLast >= minInterval && _onUpload != null) {
      _uploading++;
      try {
        await _onUpload!(fix);
        _lastUpload = now;
      } finally {
        _uploading--;
      }
    }
  }

  Future<void> dispose() => stop();
}

/// A single live position fix with optional heading/speed.
class LiveLocationFix {
  const LiveLocationFix({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;

  /// Great-circle distance (meters) to another coordinate.
  double distanceTo(double lat, double lng) {
    const r = 6371000.0;
    final dLat = _rad(lat - latitude);
    final dLng = _rad(lng - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(latitude)) *
            math.cos(_rad(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double deg) => deg * math.pi / 180.0;
}
