import 'subject.dart';

/// School (sekolah) resource.
class School {
  const School({
    required this.id,
    this.kecamatanId,
    this.kelurahanId,
    this.kecamatan,
    this.kelurahan,
    this.name,
    this.schoolType,
    this.npsn,
    this.address,
    this.latitude,
    this.longitude,
    this.condition,
    this.studentsMale,
    this.studentsFemale,
    this.totalStudents,
    this.teachers,
    this.classes,
    this.capacity,
    this.libraryPercentage,
    this.scienceLabPercentage,
    this.computerLabPercentage,
    this.teacherRoomPercentage,
    this.toiletPercentage,
    this.worshipRoomPercentage,
    this.isActive,
    this.subjects = const [],
  });

  final int id;
  final int? kecamatanId;
  final int? kelurahanId;
  final String? kecamatan;
  final String? kelurahan;
  final String? name;
  final String? schoolType;
  final String? npsn;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? condition;
  final int? studentsMale;
  final int? studentsFemale;
  final int? totalStudents;
  final int? teachers;
  final int? classes;
  final int? capacity;
  final double? libraryPercentage;
  final double? scienceLabPercentage;
  final double? computerLabPercentage;
  final double? teacherRoomPercentage;
  final double? toiletPercentage;
  final double? worshipRoomPercentage;
  final bool? isActive;
  final List<Subject> subjects;

  String get statusLabel => isActive == true ? 'aktif' : 'tidak aktif';

  factory School.fromJson(Map<String, dynamic> json) {
    List<Subject> subjects = const [];
    if (json['subjects'] is List) {
      subjects = (json['subjects'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Subject.fromJson)
          .toList();
    }
    return School(
      id: (json['id'] as num).toInt(),
      kecamatanId: (json['kecamatan_id'] as num?)?.toInt(),
      kelurahanId: (json['kelurahan_id'] as num?)?.toInt(),
      kecamatan: json['kecamatan'] as String?,
      kelurahan: json['kelurahan'] as String?,
      name: json['name'] as String?,
      schoolType: json['school_type'] as String?,
      npsn: json['npsn'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      studentsMale: (json['students_male'] as num?)?.toInt(),
      studentsFemale: (json['students_female'] as num?)?.toInt(),
      totalStudents: (json['total_students'] as num?)?.toInt(),
      teachers: (json['teachers'] as num?)?.toInt(),
      classes: (json['classes'] as num?)?.toInt(),
      capacity: (json['capacity'] as num?)?.toInt(),
      libraryPercentage: (json['library_percentage'] as num?)?.toDouble(),
      scienceLabPercentage: (json['science_lab_percentage'] as num?)
          ?.toDouble(),
      computerLabPercentage: (json['computer_lab_percentage'] as num?)
          ?.toDouble(),
      teacherRoomPercentage: (json['teacher_room_percentage'] as num?)
          ?.toDouble(),
      toiletPercentage: (json['toilet_percentage'] as num?)?.toDouble(),
      worshipRoomPercentage: (json['worship_room_percentage'] as num?)
          ?.toDouble(),
      isActive: json['is_active'] as bool?,
      subjects: subjects,
    );
  }

  /// Builds the request body for create/update, omitting null values.
  Map<String, dynamic> toRequest() {
    return {
      if (kecamatanId != null) 'kecamatan_id': kecamatanId,
      if (kelurahanId != null) 'kelurahan_id': kelurahanId,
      if (name != null) 'name': name,
      if (schoolType != null) 'school_type': schoolType,
      if (npsn != null) 'npsn': npsn,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (studentsMale != null) 'students_male': studentsMale,
      if (studentsFemale != null) 'students_female': studentsFemale,
      if (teachers != null) 'teachers': teachers,
      if (classes != null) 'classes': classes,
      if (capacity != null) 'capacity': capacity,
      if (libraryPercentage != null) 'library_percentage': libraryPercentage,
      if (scienceLabPercentage != null)
        'science_lab_percentage': scienceLabPercentage,
      if (computerLabPercentage != null)
        'computer_lab_percentage': computerLabPercentage,
      if (toiletPercentage != null) 'toilet_percentage': toiletPercentage,
      if (worshipRoomPercentage != null)
        'worship_room_percentage': worshipRoomPercentage,
      if (isActive != null) 'is_active': isActive,
      'subjects': subjects.map((s) => s.id).toList(),
    };
  }
}
