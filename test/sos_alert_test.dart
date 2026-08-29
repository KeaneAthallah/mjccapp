import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/data/models/sos_alert.dart';

void main() {
  test('SosAlert parses a full API payload', () {
    final alert = SosAlert.fromJson(const {
      'id': 7,
      'user_id': 3,
      'user': {'id': 3, 'name': 'Budi', 'role': 'viewer'},
      'latitude': -2.0584032,
      'longitude': 121.9005688,
      'accuracy': 18.0,
      'status': 'acknowledged',
      'message': 'Mohon bantuan.',
      'response_message': 'Permintaan SOS telah diterima.',
      'responded_by': 1,
      'responded_at': '2026-08-29T10:15:00+08:00',
      'resolved_at': null,
      'created_at': '2026-08-29T10:00:00+08:00',
      'updated_at': '2026-08-29T10:15:00+08:00',
      'is_owner': true,
      'can_manage': false,
    });

    expect(alert.id, 7);
    expect(alert.userId, 3);
    expect(alert.userName, 'Budi');
    expect(alert.latitude, -2.0584032);
    expect(alert.accuracy, 18.0);
    expect(alert.status, SosAlert.statusAcknowledged);
    expect(alert.statusLabel, 'Diterima');
    expect(alert.isOpen, isTrue);
    expect(alert.isActive, isFalse);
    expect(alert.responseMessage, 'Permintaan SOS telah diterima.');
    expect(alert.respondedAt, isNotNull);
    expect(alert.isOwner, isTrue);
    expect(alert.canManage, isFalse);
  });

  test('SosAlert open and closed statuses resolve correctly', () {
    SosAlert make(String status) => SosAlert.fromJson({
          'id': 1,
          'user_id': 1,
          'latitude': 0.0,
          'longitude': 0.0,
          'status': status,
        });

    expect(make(SosAlert.statusActive).isOpen, isTrue);
    expect(make(SosAlert.statusAcknowledged).isOpen, isTrue);
    expect(make(SosAlert.statusResponding).isOpen, isTrue);
    expect(make(SosAlert.statusResolved).isOpen, isFalse);
    expect(make(SosAlert.statusCancelled).isOpen, isFalse);
    expect(make(SosAlert.statusResolved).statusLabel, 'Selesai');
    expect(make(SosAlert.statusCancelled).statusLabel, 'Dibatalkan');
  });

  test('SosAlert tolerates partial payloads (list view shape)', () {
    final alert = SosAlert.fromJson(const {
      'id': 1,
      'user_id': 2,
      'user': {'id': 2, 'name': 'Sari', 'role': 'operator'},
      'latitude': -2.1,
      'longitude': 121.9,
      'status': 'active',
      'created_at': '2026-08-29T09:00:00+08:00',
    });

    expect(alert.userName, 'Sari');
    expect(alert.userRole, 'operator');
    expect(alert.accuracy, isNull);
    expect(alert.isActive, isTrue);
  });
}