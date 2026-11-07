import 'dart:ui' as ui;

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

  // Without Impeller, liquid glass falls back to a plain backdrop blur with its preset's sigma.
  testWidgets(
    'the switch turns liquid glass on and off',
    skip: ui.ImageFilter.isShaderFilterSupported,
    (tester) async {
      await tester.pumpWidget(const MyApp());
      ui.ImageFilter? filter() =>
          tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter;
      final plain = filter();

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(filter(), isNot(plain));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(filter(), plain);
    },
  );
}
