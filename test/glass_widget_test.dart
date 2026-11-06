import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass/glass.dart';

const _child = SizedBox(key: Key('child'), width: 100, height: 100);

Future<void> _pump(WidgetTester tester, Widget widget) {
  return tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: widget),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(BackdropFilter),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('asGlass', () {
    testWidgets('returns the original widget when disabled', (tester) async {
      await _pump(tester, _child.asGlass(enabled: false));

      expect(find.byKey(const Key('child')), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('wraps the child in ClipRRect > BackdropFilter',
        (tester) async {
      await _pump(tester, _child.asGlass());

      expect(find.byType(ClipRRect), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ClipRRect),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byKey(const Key('child')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('works on custom Widget subclasses', (tester) async {
      await _pump(tester, const _CustomWidget().asGlass());

      expect(find.byType(_CustomWidget), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('passes clip settings to ClipRRect', (tester) async {
      final radius = BorderRadius.circular(12);
      await _pump(
        tester,
        _child.asGlass(
          clipBorderRadius: radius,
          clipBehavior: Clip.hardEdge,
        ),
      );

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, radius);
      expect(clip.clipBehavior, Clip.hardEdge);
      expect(clip.clipper, isNull);
    });

    testWidgets('still accepts the deprecated clipBehaviour', (tester) async {
      // ignore: deprecated_member_use_from_same_package
      await _pump(tester, _child.asGlass(clipBehaviour: Clip.hardEdge));

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.clipBehavior, Clip.hardEdge);
    });

    testWidgets('clipBehavior wins over the deprecated clipBehaviour',
        (tester) async {
      await _pump(
        tester,
        _child.asGlass(
          clipBehavior: Clip.none,
          // ignore: deprecated_member_use_from_same_package
          clipBehaviour: Clip.hardEdge,
        ),
      );

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.clipBehavior, Clip.none);
    });

    testWidgets('defaults to Clip.antiAlias', (tester) async {
      await _pump(tester, _child.asGlass());

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.clipBehavior, Clip.antiAlias);
    });

    testWidgets('passes a custom clipper to ClipRRect', (tester) async {
      final clipper = _TestClipper();
      await _pump(tester, _child.asGlass(clipper: clipper));

      expect(tester.widget<ClipRRect>(find.byType(ClipRRect)).clipper, clipper);
    });

    testWidgets('applies blur and tile mode to the backdrop filter',
        (tester) async {
      await _pump(
        tester,
        _child.asGlass(blurX: 3, blurY: 7, tileMode: TileMode.mirror),
      );

      final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
      expect(
        filter.filter,
        ImageFilter.blur(sigmaX: 3, sigmaY: 7, tileMode: TileMode.mirror),
      );
    });

    testWidgets('uses a tint gradient based on tintColor', (tester) async {
      await _pump(tester, _child.asGlass(tintColor: Colors.red));

      final gradient = _decoration(tester).gradient! as LinearGradient;
      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.end, Alignment.bottomRight);
      expect(gradient.colors, [
        Colors.red.withValues(alpha: 0.1),
        Colors.red.withValues(alpha: 0.08),
      ]);
    });

    testWidgets('has no gradient when tintColor is transparent',
        (tester) async {
      await _pump(tester, _child.asGlass(tintColor: Colors.transparent));

      expect(_decoration(tester).gradient, isNull);
    });

    testWidgets('uses the packaged noise image when frosted', (tester) async {
      await _pump(tester, _child.asGlass());

      final image = _decoration(tester).image!;
      expect(image.fit, BoxFit.cover);
      expect(
        image.image,
        const AssetImage('images/noise.png', package: 'glass'),
      );
    });

    testWidgets('has no noise image when not frosted', (tester) async {
      await _pump(tester, _child.asGlass(frosted: false));

      expect(_decoration(tester).image, isNull);
    });
  });
}

class _CustomWidget extends StatelessWidget {
  const _CustomWidget();

  @override
  Widget build(BuildContext context) => _child;
}

class _TestClipper extends CustomClipper<RRect> {
  @override
  RRect getClip(Size size) => RRect.fromLTRBR(0, 0, 10, 10, Radius.zero);

  @override
  bool shouldReclip(covariant CustomClipper<RRect> oldClipper) => false;
}
