/// Audit log entry returned by `GET /audit`.
class ActivityLog {
  const ActivityLog({
    required this.id,
    this.userId,
    this.user,
    this.action,
    this.resourceType,
    this.resourceId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.description,
    this.createdAt,
  });

  final int id;
  final int? userId;
  final Map<String, dynamic>? user;
  final String? action;
  final String? resourceType;
  final int? resourceId;
  final dynamic oldValues;
  final dynamic newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? description;
  final DateTime? createdAt;

  String get userName => user?['name'] as String? ?? '';

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      user: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
      action: json['action'] as String?,
      resourceType: json['resource_type'] as String?,
      resourceId: (json['resource_id'] as num?)?.toInt(),
      oldValues: json['old_values'],
      newValues: json['new_values'],
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
