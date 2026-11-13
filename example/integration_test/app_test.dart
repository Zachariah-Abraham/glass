// Flutter 3.50 deprecates material.dart; material_ui does not exist on the minimum Flutter 3.29.
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example app renders glass on a real engine and toggles it', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Night sky'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.tap(find.text('Night sky'));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.tap(find.text('Night sky'));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
