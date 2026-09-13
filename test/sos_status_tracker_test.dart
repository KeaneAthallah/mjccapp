import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/data/models/sos_alert.dart';
import 'package:mjcc/presentation/widgets/sos/sos_status_tracker.dart';

void main() {
  testWidgets('tracker shows the constraint banner when constrained',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SosStatusTracker(
          alert: SosAlert.fromJson(const {
            'id': 1,
            'user_id': 1,
            'latitude': 0.0,
            'longitude': 0.0,
            'status': 'constrained',
            'constraint_type': 'cannot_reach',
            'constraint_reason': 'Jalan tertutup longsor.',
          }),
        ),
      ),
    ));

    expect(find.text('Petugas Terkendala'), findsOneWidget);
    expect(find.text('Jalan tertutup longsor.'), findsOneWidget);
    expect(find.text('SOS Dikirim'), findsOneWidget);
  });

  testWidgets('tracker shows the delayed constraint label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SosStatusTracker(
          alert: SosAlert.fromJson(const {
            'id': 2,
            'user_id': 1,
            'latitude': 0.0,
            'longitude': 0.0,
            'status': 'constrained',
            'constraint_type': 'delayed',
            'constraint_reason': 'Kemacetan parah.',
          }),
        ),
      ),
    ));

    expect(
      find.text('Terlambat / terkendala di perjalanan'),
      findsOneWidget,
    );
  });

  testWidgets('tracker does not show the banner for a resolved alert',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SosStatusTracker(
          alert: SosAlert.fromJson(const {
            'id': 3,
            'user_id': 1,
            'latitude': 0.0,
            'longitude': 0.0,
            'status': 'resolved',
          }),
        ),
      ),
    ));

    expect(find.text('Petugas Terkendala'), findsNothing);
    expect(find.text('SOS Selesai'), findsOneWidget);
  });
}