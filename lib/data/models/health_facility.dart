/// Health facility (fasilitas kesehatan) resource.
class HealthFacility {
  const HealthFacility({
    required this.id,
    this.kecamatanId,
    this.kecamatan,
    this.name,
    this.facilityType,
    this.address,
    this.latitude,
    this.longitude,
    this.condition,
    this.beds,
    this.doctors,
    this.nurses,
    this.midwives,
    this.status,
    this.phone,
    this.description,
  });

  final int id;
  final int? kecamatanId;
  final String? kecamatan;
  final String? name;
  final String? facilityType;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? condition;
  final int? beds;
  final int? doctors;
  final int? nurses;
  final int? midwives;
  final String? status;
  final String? phone;
  final String? description;

  int get workforce => (doctors ?? 0) + (nurses ?? 0) + (midwives ?? 0);

  factory HealthFacility.fromJson(Map<String, dynamic> json) {
    return HealthFacility(
      id: (json['id'] as num).toInt(),
      kecamatanId: (json['kecamatan_id'] as num?)?.toInt(),
      kecamatan: json['kecamatan'] as String?,
      name: json['name'] as String?,
      facilityType: json['facility_type'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      beds: (json['beds'] as num?)?.toInt(),
      doctors: (json['doctors'] as num?)?.toInt(),
      nurses: (json['nurses'] as num?)?.toInt(),
      midwives: (json['midwives'] as num?)?.toInt(),
      status: json['status'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (kecamatanId != null) 'kecamatan_id': kecamatanId,
      if (name != null) 'name': name,
      if (facilityType != null) 'facility_type': facilityType,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (beds != null) 'beds': beds,
      if (doctors != null) 'doctors': doctors,
      if (nurses != null) 'nurses': nurses,
      if (midwives != null) 'midwives': midwives,
      if (status != null) 'status': status,
      if (phone != null) 'phone': phone,
      if (description != null) 'description': description,
    };
  }
}
