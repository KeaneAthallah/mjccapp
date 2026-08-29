/// SOS / emergency alert resource.
class SosAlert {
  const SosAlert({
    required this.id,
    required this.userId,
    this.userName,
    this.userRole,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.status,
    this.message,
    this.responseMessage,
    this.respondedAt,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.isOwner = false,
    this.canManage = false,
  });

  static const String statusActive = 'active';
  static const String statusAcknowledged = 'acknowledged';
  static const String statusResponding = 'responding';
  static const String statusResolved = 'resolved';
  static const String statusCancelled = 'cancelled';

  final int id;
  final int userId;
  final String? userName;
  final String? userRole;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String status;
  final String? message;
  final String? responseMessage;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isOwner;
  final bool canManage;

  bool get isOpen => const {
        statusActive,
        statusAcknowledged,
        statusResponding,
      }.contains(status);

  bool get isActive => status == statusActive;

  String get statusLabel => switch (status) {
        statusActive => 'Aktif',
        statusAcknowledged => 'Diterima',
        statusResponding => 'Menuju Lokasi',
        statusResolved => 'Selesai',
        statusCancelled => 'Dibatalkan',
        _ => status,
      };

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user'] is Map<String, dynamic>
          ? (json['user'] as Map<String, dynamic>)['name'] as String?
          : null,
      userRole: json['user'] is Map<String, dynamic>
          ? (json['user'] as Map<String, dynamic>)['role'] as String?
          : null,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      status: json['status'] as String? ?? statusActive,
      message: json['message'] as String?,
      responseMessage: json['response_message'] as String?,
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      isOwner: json['is_owner'] as bool? ?? false,
      canManage: json['can_manage'] as bool? ?? false,
    );
  }
}