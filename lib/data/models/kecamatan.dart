/// Kecamatan (district) resource.
class Kecamatan {
  const Kecamatan({
    required this.id,
    this.name,
    this.code,
    this.latitude,
    this.longitude,
    this.description,
    this.isActive,
  });

  final int id;
  final String? name;
  final String? code;
  final double? latitude;
  final double? longitude;
  final String? description;
  final bool? isActive;

  factory Kecamatan.fromJson(Map<String, dynamic> json) {
    return Kecamatan(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      code: json['code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}
