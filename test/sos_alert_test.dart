import 'package:flutter/material.dart';
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
    expect(make(SosAlert.statusAccepted).isOpen, isTrue);
    expect(make(SosAlert.statusAcknowledged).isOpen, isTrue);
    expect(make(SosAlert.statusResponding).isOpen, isTrue);
    expect(make(SosAlert.statusOnTheWay).isOpen, isTrue);
    expect(make(SosAlert.statusArrived).isOpen, isTrue);
    expect(make(SosAlert.statusResolved).isOpen, isFalse);
    expect(make(SosAlert.statusCancelled).isOpen, isFalse);
    expect(make(SosAlert.statusResolved).statusLabel, 'Selesai');
    expect(make(SosAlert.statusCancelled).statusLabel, 'Dibatalkan');
    expect(make(SosAlert.statusAccepted).statusLabel, 'Diterima');
    expect(make(SosAlert.statusOnTheWay).statusLabel, 'Di Perjalanan');
    expect(make(SosAlert.statusArrived).statusLabel, 'Tiba di Lokasi');
  });

  test('SosAlert categories parse into labels, icons and colors', () {
    SosAlert make(String category) => SosAlert.fromJson({
          'id': 1,
          'user_id': 1,
          'latitude': 0.0,
          'longitude': 0.0,
          'status': 'active',
          'category': category,
        });

    expect(make(SosAlert.categoryMedical).categoryLabel, 'Medis');
    expect(make(SosAlert.categoryFire).categoryLabel, 'Pemadam Kebakaran');
    expect(make(SosAlert.categoryPolice).categoryLabel, 'Polisi');
    expect(make(SosAlert.categoryGeneral).categoryLabel, 'Umum');
    expect(make(SosAlert.categoryMedical).categoryIcon, Icons.medical_services_outlined);
    expect(make(SosAlert.categoryFire).categoryIcon, Icons.local_fire_department_outlined);
    expect(make(SosAlert.categoryPolice).categoryIcon, Icons.local_police_outlined);
    expect(make(SosAlert.categoryGeneral).categoryIcon, Icons.help_outline);
    expect(make(SosAlert.categoryMedical).categoryColor, isNotNull);
  });

  test('SosAlert parses accepted responder fields', () {
    final alert = SosAlert.fromJson({
      'id': 10,
      'user_id': 5,
      'latitude': -2.0,
      'longitude': 121.0,
      'status': 'accepted',
      'category': 'medical',
      'accepted_by': 3,
      'accepted_by_user': {'id': 3, 'name': 'Dokter Andi'},
      'accepted_at': '2026-09-09T11:30:00+08:00',
    });

    expect(alert.status, SosAlert.statusAccepted);
    expect(alert.category, SosAlert.categoryMedical);
    expect(alert.acceptedBy, 3);
    expect(alert.acceptedByUser, 'Dokter Andi');
    expect(alert.acceptedAt, isNotNull);
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
    expect(alert.category, SosAlert.categoryGeneral);
  });
}