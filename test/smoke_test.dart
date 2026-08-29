import 'package:flutter_test/flutter_test.dart';

import 'package:mjcc/main.dart';

void main() {
  testWidgets('app builds the root screen', (tester) async {
    await tester.pumpWidget(const MJCCApp());
    await tester.pump();

    expect(find.byType(MJCCApp), findsOneWidget);
  });
}
