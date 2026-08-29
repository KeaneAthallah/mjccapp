/// Tipkamtikmas resource.
class Tipkamtikmas {
  const Tipkamtikmas({
    required this.id,
    this.kecamatanId,
    this.kelurahanId,
    this.kecamatan,
    this.kelurahan,
    this.title,
    this.description,
    this.status,
    this.latitude,
    this.longitude,
  });

  final int id;
  final int? kecamatanId;
  final int? kelurahanId;
  final String? kecamatan;
  final String? kelurahan;
  final String? title;
  final String? description;
  final String? status;
  final double? latitude;
  final double? longitude;

  factory Tipkamtikmas.fromJson(Map<String, dynamic> json) {
    return Tipkamtikmas(
      id: (json['id'] as num).toInt(),
      kecamatanId: (json['kecamatan_id'] as num?)?.toInt(),
      kelurahanId: (json['kelurahan_id'] as num?)?.toInt(),
      kecamatan: json['kecamatan'] as String?,
      kelurahan: json['kelurahan'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (kecamatanId != null) 'kecamatan_id': kecamatanId,
      if (kelurahanId != null) 'kelurahan_id': kelurahanId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
