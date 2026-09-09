class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;
  bool get isSos => type == 'sos';
  bool get isSystem => type == 'system';

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
