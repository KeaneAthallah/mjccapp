import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// A successfully resolved device location.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
}

/// Thrown with a user-friendly Indonesian message when a location cannot be
/// obtained (permissions, GPS disabled, timeout).
class LocationFailure implements Exception {
  const LocationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps `geolocator` so the SOS flow gets a single, guarded API with clean
/// Indonesian error messages and safe timeout handling.
class LocationService {
  const LocationService();

  static const Duration _timeout = Duration(seconds: 15);

  /// Resolves the current position, requesting permission if needed.
  Future<LocationFix> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        'Layanan lokasi perangkat mati. Aktifkan GPS terlebih dahulu.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Izin lokasi ditolak. Izinkan akses lokasi untuk mengirim SOS.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Izin lokasi diblokir permanen. Aktifkan melalui pengaturan perangkat.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );
      return LocationFix(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } on TimeoutException {
      throw const LocationFailure(
        'Waktu pencarian lokasi habis. Coba lagi di area terbuka.',
      );
    } catch (_) {
      throw const LocationFailure(
        'Gagal mendapatkan lokasi. Pastikan GPS aktif dan coba lagi.',
      );
    }
  }
}