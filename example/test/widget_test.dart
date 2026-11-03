import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('tapping the button toggles the glass effect', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Night sky'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.tap(find.text('Night sky'));
    await tester.pump();

    expect(find.byType(BackdropFilter), findsNothing);

    await tester.tap(find.text('Night sky'));
    await tester.pump();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
