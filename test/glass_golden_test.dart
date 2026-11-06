@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass/glass.dart';

const _size = Size(240, 240);
const _sceneKey = Key('scene');

/// A fixed-size scene with high-contrast stripes behind a centered glass pane,
/// so blur, tint and noise are all visible. It contains no text, so the output
/// doesn't depend on fonts.
Widget _scene(Widget Function(Widget pane) glass) {
  const colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];
  return Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(
      key: _sceneKey,
      child: SizedBox.fromSize(
        size: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final color in colors)
                    Expanded(child: ColoredBox(color: color)),
                ],
              ),
            ),
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 8; i++)
                    Expanded(
                      child: ColoredBox(
                        color: i.isEven ? Colors.black26 : Colors.white24,
                      ),
                    ),
                ],
              ),
            ),
            glass(const SizedBox(width: 140, height: 140)),
          ],
        ),
      ),
    ),
  );
}

Future<void> _expectGolden(
  WidgetTester tester,
  String name,
  Widget Function(Widget pane) glass,
) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_scene(glass));
  // The noise texture loads asynchronously from the asset bundle.
  await tester.runAsync(() async {
    for (final element in find.byType(Container).evaluate()) {
      final decoration = (element.widget as Container).decoration;
      final image = decoration is BoxDecoration ? decoration.image : null;
      if (image != null) {
        await precacheImage(image.image, element);
      }
    }
  });
  await tester.pump();

  await expectLater(
    find.byKey(_sceneKey),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  group('asGlass goldens', () {
    testWidgets('default', (tester) async {
      await _expectGolden(tester, 'default', (pane) => pane.asGlass());
    });

    testWidgets('strong blur', (tester) async {
      await _expectGolden(
        tester,
        'strong_blur',
        (pane) => pane.asGlass(blurX: 25, blurY: 25),
      );
    });

    testWidgets('not frosted', (tester) async {
      await _expectGolden(
        tester,
        'not_frosted',
        (pane) => pane.asGlass(frosted: false),
      );
    });

    testWidgets('colored tint', (tester) async {
      await _expectGolden(
        tester,
        'colored_tint',
        (pane) => pane.asGlass(tintColor: Colors.red, frosted: false),
      );
    });

    testWidgets('blur only', (tester) async {
      await _expectGolden(
        tester,
        'blur_only',
        (pane) => pane.asGlass(tintColor: Colors.transparent, frosted: false),
      );
    });

    testWidgets('rounded corners', (tester) async {
      await _expectGolden(
        tester,
        'rounded_corners',
        (pane) => pane.asGlass(clipBorderRadius: BorderRadius.circular(40)),
      );
    });

    testWidgets('disabled', (tester) async {
      await _expectGolden(
        tester,
        'disabled',
        (pane) => pane.asGlass(enabled: false),
      );
    });
  });
}
