/// Subject (mata pelajaran) resource.
class Subject {
  const Subject({
    required this.id,
    this.name,
    this.code,
    this.description,
    this.isActive,
  });

  final int id;
  final String? name;
  final String? code;
  final String? description;
  final bool? isActive;

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}
