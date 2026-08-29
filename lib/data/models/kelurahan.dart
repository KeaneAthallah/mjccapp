/// Kelurahan (sub-district) resource.
class Kelurahan {
  const Kelurahan({
    required this.id,
    this.kecamatanId,
    this.kecamatan,
    this.name,
    this.code,
    this.latitude,
    this.longitude,
    this.population,
    this.status,
  });

  final int id;
  final int? kecamatanId;
  final String? kecamatan;
  final String? name;
  final String? code;
  final double? latitude;
  final double? longitude;
  final int? population;
  final String? status;

  factory Kelurahan.fromJson(Map<String, dynamic> json) {
    return Kelurahan(
      id: (json['id'] as num).toInt(),
      kecamatanId: (json['kecamatan_id'] as num?)?.toInt(),
      kecamatan: json['kecamatan'] as String?,
      name: json['name'] as String?,
      code: json['code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      population: (json['population'] as num?)?.toInt(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'kecamatan_id': kecamatanId, 'name': name};
  }
}
