/// Poskamling resource.
class Poskamling {
  const Poskamling({
    required this.id,
    this.kecamatanId,
    this.kelurahanId,
    this.kecamatan,
    this.kelurahan,
    this.name,
    this.latitude,
    this.longitude,
    this.status,
    this.isActive,
  });

  final int id;
  final int? kecamatanId;
  final int? kelurahanId;
  final String? kecamatan;
  final String? kelurahan;
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? status;
  final bool? isActive;

  factory Poskamling.fromJson(Map<String, dynamic> json) {
    return Poskamling(
      id: (json['id'] as num).toInt(),
      kecamatanId: (json['kecamatan_id'] as num?)?.toInt(),
      kelurahanId: (json['kelurahan_id'] as num?)?.toInt(),
      kecamatan: json['kecamatan'] as String?,
      kelurahan: json['kelurahan'] as String?,
      name: json['name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String?,
      isActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (kecamatanId != null) 'kecamatan_id': kecamatanId,
      if (kelurahanId != null) 'kelurahan_id': kelurahanId,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (status != null) 'status': status,
      if (isActive != null) 'is_active': isActive,
    };
  }
}
