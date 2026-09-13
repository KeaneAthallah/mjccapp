import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/data/models/sos_alert.dart';
import 'package:mjcc/presentation/widgets/sos/constraint_dialog.dart';

void main() {
  Future<void> pumpOpener(
    WidgetTester tester,
    GlobalKey buttonKey,
    ValueChanged<ConstraintInput?> onResult,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            key: buttonKey,
            onPressed: () async {
              onResult(await showConstraintDialog(context));
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
  }

  testWidgets('requires a reason before reporting', (tester) async {
    final key = GlobalKey();
    await pumpOpener(tester, key, (_) {});

    await tester.tap(find.text('Laporkan'));
    await tester.pump();

    expect(find.text('Alasan wajib diisi.'), findsOneWidget);
  });

  testWidgets('returns the selected type and reason on submit',
      (tester) async {
    ConstraintInput? result;
    final key = GlobalKey();
    await pumpOpener(tester, key, (r) => result = r);

    await tester.tap(find.text('Tidak bisa mencapai lokasi'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Jalan tertutup longsor.');
    await tester.tap(find.text('Laporkan'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.type, SosAlert.constraintCannotReach);
    expect(result!.reason, 'Jalan tertutup longsor.');
  });

  testWidgets('dismissing the dialog returns null', (tester) async {
    ConstraintInput? result;
    final key = GlobalKey();
    await pumpOpener(tester, key, (r) => result = r);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}