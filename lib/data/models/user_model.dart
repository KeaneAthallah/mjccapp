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

enum ResponderType {
  medical,
  fire,
  police;

  static ResponderType? fromString(String? value) {
    return switch (value) {
      'medical' => ResponderType.medical,
      'fire' => ResponderType.fire,
      'police' => ResponderType.police,
      _ => null,
    };
  }

  String get wire => name;

  String get label => switch (this) {
        ResponderType.medical => 'Medis',
        ResponderType.fire => 'Pemadam Kebakaran',
        ResponderType.police => 'Polisi',
      };
}

/// User as returned by `POST /login`, `GET /me`, `GET /profile` and the
/// admin `users` resource.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.responderType,
    this.emailVerified = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final ResponderType? responderType;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isResponder => responderType != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      responderType: ResponderType.fromString(
        json['responder_type'] as String?,
      ),
      emailVerified: json['email_verified'] as bool? ?? true,
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
      'responder_type': responderType?.wire,
      'email_verified': emailVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
