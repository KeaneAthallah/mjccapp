/// User role within MJCC.
enum UserRole {
  admin,
  operator,
  viewer;

  static UserRole fromString(String? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      'operator' => UserRole.operator,
      'viewer' => UserRole.viewer,
      _ => UserRole.viewer,
    };
  }

  String get wire => name;

  bool get canWrite => this != UserRole.viewer;
  bool get isAdmin => this == UserRole.admin;
}

/// User as returned by `POST /login`, `GET /me`, `GET /profile` and the
/// admin `users` resource.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.wire,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
