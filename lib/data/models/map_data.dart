import 'kecamatan.dart';

/// A map marker returned by `GET /maps`.
class MapMarker {
  const MapMarker({
    required this.id,
    required this.type,
    required this.sector,
    required this.name,
    this.latitude,
    this.longitude,
    this.status,
    this.kecamatan,
    this.kelurahan,
  });

  final int id;
  final String type;
  final String sector;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? status;
  final String? kecamatan;
  final String? kelurahan;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory MapMarker.fromJson(Map<String, dynamic> json) {
    return MapMarker(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String?,
      kecamatan: json['kecamatan'] as String?,
      kelurahan: json['kelurahan'] as String?,
    );
  }

  static const List<String> markerTypes = [
    'school',
    'polsek',
    'tipkamtikmas',
    'poskamling',
    'market',
    'health_facility',
  ];
}

/// Response of `GET /maps`.
class MapData {
  const MapData({required this.markers, required this.kecamatans});

  final List<MapMarker> markers;
  final List<Kecamatan> kecamatans;

  factory MapData.fromJson(Map<String, dynamic> json) {
    final markers = (json['markers'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MapMarker.fromJson)
        .toList();
    final kecamatans = (json['kecamatans'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Kecamatan.fromJson)
        .toList();
    return MapData(markers: markers, kecamatans: kecamatans);
  }
}
