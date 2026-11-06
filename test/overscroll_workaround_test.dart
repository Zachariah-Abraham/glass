import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass/glass.dart';

// Documents the "Known limitations" section of the README: on Android with Material 3, Flutter
// wraps scrollables in a stretch overscroll effect that hides the backdrop of any glass inside
// them. The README's workaround turns that effect off.
Widget _app({required bool overscroll}) {
  final scrollView = SingleChildScrollView(
    child: Column(
      children: const [SizedBox(height: 2000, child: Text('content'))],
    ).asGlass(),
  );
  return MaterialApp(
    theme: ThemeData(platform: TargetPlatform.android, useMaterial3: true),
    home: Builder(
      builder: (context) => ScrollConfiguration(
        behavior:
            ScrollConfiguration.of(context).copyWith(overscroll: overscroll),
        child: scrollView,
      ),
    ),
  );
}

void main() {
  testWidgets('Android Material 3 stretches the scroll view holding the glass',
      (tester) async {
    await tester.pumpWidget(_app(overscroll: true));

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('overscroll: false removes the stretch effect', (tester) async {
    await tester.pumpWidget(_app(overscroll: false));

    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
