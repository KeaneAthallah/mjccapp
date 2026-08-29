/// Police sector (Polsek) resource — no soft deletes.
class Polsek {
  const Polsek({
    required this.id,
    this.kecamatanId,
    this.kecamatan,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.personnelCount,
    this.poskamlingCount,
    this.status,
  });

  final int id;
  final int? kecamatanId;
  final String? kecamatan;
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? personnelCount;
  final int? poskamlingCount;
  final String? status;

  factory Polsek.fromJson(Map<String, dynamic> json) {
    return Polsek(
      id: (json['id'] as num).toInt(),
      kecamatanId: (json['kecamatan_id'] as num?)?.toInt(),
      kecamatan: json['kecamatan'] as String?,
      name: json['name'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      personnelCount: (json['personnel_count'] as num?)?.toInt(),
      poskamlingCount: (json['poskamling_count'] as num?)?.toInt(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (kecamatanId != null) 'kecamatan_id': kecamatanId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (personnelCount != null) 'personnel_count': personnelCount,
      if (poskamlingCount != null) 'poskamling_count': poskamlingCount,
      if (status != null) 'status': status,
    };
  }
}
