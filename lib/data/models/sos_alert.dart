import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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
    this.category = categoryGeneral,
    this.message,
    this.responseMessage,
    this.acceptedBy,
    this.acceptedByUser,
    this.acceptedAt,
    this.constraintType,
    this.constraintTypeLabel,
    this.constraintReason,
    this.constrainedBy,
    this.constrainedByUser,
    this.constrainedAt,
    this.respondedAt,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.isOwner = false,
    this.canManage = false,
  });

  static const String statusActive = 'active';
  static const String statusAccepted = 'accepted';
  static const String statusAcknowledged = 'acknowledged';
  static const String statusResponding = 'responding';
  static const String statusOnTheWay = 'on_the_way';
  static const String statusArrived = 'arrived';
  static const String statusConstrained = 'constrained';
  static const String statusResolved = 'resolved';
  static const String statusCancelled = 'cancelled';

  /// Constraint types reported by the petugas.
  static const String constraintCannotReach = 'cannot_reach';
  static const String constraintDelayed = 'delayed';

  static const String categoryGeneral = 'general';
  static const String categoryMedical = 'medical';
  static const String categoryFire = 'fire';
  static const String categoryPolice = 'police';

  final int id;
  final int userId;
  final String? userName;
  final String? userRole;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String status;
  final String category;
  final String? message;
  final String? responseMessage;
  final int? acceptedBy;
  final String? acceptedByUser;
  final DateTime? acceptedAt;
  final String? constraintType;
  final String? constraintTypeLabel;
  final String? constraintReason;
  final int? constrainedBy;
  final String? constrainedByUser;
  final DateTime? constrainedAt;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isOwner;
  final bool canManage;

  bool get isOpen => const {
        statusActive,
        statusAccepted,
        statusAcknowledged,
        statusResponding,
        statusOnTheWay,
        statusArrived,
        statusConstrained,
      }.contains(status);

  bool get isActive => status == statusActive;

  String get statusLabel => switch (status) {
        statusActive => 'Aktif',
        statusAccepted => 'Diterima',
        statusAcknowledged => 'Diterima',
        statusResponding => 'Menuju Lokasi',
        statusOnTheWay => 'Di Perjalanan',
        statusArrived => 'Tiba di Lokasi',
        statusConstrained => 'Terkendala',
        statusResolved => 'Selesai',
        statusCancelled => 'Dibatalkan',
        _ => status,
      };

  /// Indonesian label for the reported constraint; falls back to the label
  /// sent by the API when available.
  String? get constraintTypeDisplay {
    final fromServer = constraintTypeLabel;
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;
    return switch (constraintType) {
      constraintCannotReach => 'Tidak bisa menjangkau lokasi',
      constraintDelayed => 'Terlambat / terkendala di perjalanan',
      _ => null,
    };
  }

  String get categoryLabel => switch (category) {
        categoryGeneral => 'Umum',
        categoryMedical => 'Medis',
        categoryFire => 'Pemadam Kebakaran',
        categoryPolice => 'Polisi',
        _ => category,
      };

  IconData get categoryIcon => switch (category) {
        categoryGeneral => Icons.help_outline,
        categoryMedical => Icons.medical_services_outlined,
        categoryFire => Icons.local_fire_department_outlined,
        categoryPolice => Icons.local_police_outlined,
        _ => Icons.help_outline,
      };

  Color get categoryColor => switch (category) {
        categoryGeneral => AppColors.sosGeneral,
        categoryMedical => AppColors.sosMedical,
        categoryFire => AppColors.sosFire,
        categoryPolice => AppColors.sosPolice,
        _ => AppColors.sosGeneral,
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
      category: json['category'] as String? ?? categoryGeneral,
      message: json['message'] as String?,
      responseMessage: json['response_message'] as String?,
      acceptedBy: (json['accepted_by'] as num?)?.toInt(),
      acceptedByUser: json['accepted_by_user'] is Map<String, dynamic>
          ? (json['accepted_by_user'] as Map<String, dynamic>)['name'] as String?
          : (json['accepted_by_user'] as String?),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'] as String)
          : null,
      constraintType: json['constraint_type'] as String?,
      constraintTypeLabel: json['constraint_type_label'] as String?,
      constraintReason: json['constraint_reason'] as String?,
      constrainedBy: (json['constrained_by'] as num?)?.toInt(),
      constrainedByUser: json['constrained_by_user'] is Map<String, dynamic>
          ? (json['constrained_by_user'] as Map<String, dynamic>)['name']
              as String?
          : (json['constrained_by_user'] as String?),
      constrainedAt: json['constrained_at'] != null
          ? DateTime.tryParse(json['constrained_at'] as String)
          : null,
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
