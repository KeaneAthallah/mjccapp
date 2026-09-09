/// Latest live location of a responder assigned to an SOS alert, as returned
/// by `GET /sos/{sos}/responder-locations`.
class ResponderLocation {
  const ResponderLocation({
    required this.id,
    required this.userId,
    this.userName,
    this.responderType,
    this.responderTypeLabel,
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String? userName;
  final String? responderType;
  final String? responderTypeLabel;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;

  factory ResponderLocation.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ResponderLocation(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      userName: user is Map<String, dynamic>
          ? user['name'] as String?
          : null,
      responderType: user is Map<String, dynamic>
          ? user['responder_type'] as String?
          : null,
      responderTypeLabel: user is Map<String, dynamic>
          ? user['responder_type_label'] as String?
          : null,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}