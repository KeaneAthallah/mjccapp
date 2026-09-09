import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// A computed road route between two coordinates.
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  double get distanceKm => distanceMeters / 1000.0;

  /// Estimated travel time as a human string like "12 mnt".
  String get durationLabel {
    final minutes = durationSeconds / 60.0;
    if (minutes < 1) return '${durationSeconds.round()} dtk';
    return '${minutes.round()} mnt';
  }
}

/// Fetches real road routes using the public OSRM demo server, which is
/// OSM/OpenStreetMap-compatible and needs no API key.
///
/// To avoid excessive calls while a responder moves, only request a new route
/// when the destination (or origin) has moved beyond a threshold — handled by
/// the caller — and cache the last result.
class RoutingService {
  const RoutingService({
    this.baseUrl = 'https://router.project-osrm.org',
    this.profile = 'driving',
    this.timeout = const Duration(seconds: 20),
  });

  final String baseUrl;
  final String profile;
  final Duration timeout;

  /// Requests a driving route from [origin] to [destination]. Returns null on
  /// any network/routing error instead of throwing, so the map simply shows
  /// the markers without a route.
  Future<RouteResult?> route({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url =
        '$baseUrl/route/v1/$profile/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=false';

    try {
      final response = await Dio().get<Map<String, dynamic>>(
        url,
        options: Options(
          receiveTimeout: timeout,
          headers: {'Accept': 'application/json'},
        ),
      );
      final body = response.data;
      final routes = body?['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) return null;

      final points = <LatLng>[
        for (final c in coordinates)
          if (c is List && c.length >= 2)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];

      return RouteResult(
        points: points,
        distanceMeters: ((route['distance'] as num?)?.toDouble() ?? 0),
        durationSeconds: ((route['duration'] as num?)?.toDouble() ?? 0),
      );
    } catch (_) {
      return null;
    }
  }

  /// A simulated fallback is deliberately NOT implemented — a straight line
  /// is never returned. [route] only ever returns real OSRM data or null.
}
