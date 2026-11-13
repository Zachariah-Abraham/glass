// Tests of the live liquid glass shader path. The shader only runs on Impeller,
// so these are skipped unless the tests run with `flutter test --enable-impeller`.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass/glass.dart';

// Skipped without Impeller (run `flutter test --enable-impeller`).
final _skip = !ui.ImageFilter.isShaderFilterSupported;

/// The package loads its shader as `packages/glass/shaders/...`, but in the
/// package's own tests the asset only exists under `shaders/...`. Copy it to
/// the key an app would use.
void _bundleShaderUnderPackageKey() {
  const dir = 'build/unit_test_assets';
  final source = File('$dir/shaders/liquid_glass.frag');
  final target = File('$dir/packages/glass/shaders/liquid_glass.frag');
  // Always overwrite: a copy left by another Flutter version won't load.
  if (source.existsSync()) {
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
  }
}

/// Pumps [widget] and waits for the shader to load.
Future<void> _pumpLive(WidgetTester tester, Widget widget) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(200, 200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(textDirection: TextDirection.ltr, child: widget),
  );
  // The first load compiles the shader and can take a while. Once it is
  // done, the plain BackdropFilter is gone.
  for (
    var i = 0;
    i < 100 && find.byType(BackdropFilter).evaluate().isNotEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(
    find.byType(BackdropFilter),
    findsNothing,
    reason: 'the liquid shader did not load',
  );
  await tester.pump();
}

/// The backdrop filter layers in the current scene.
List<BackdropFilterLayer> _backdropLayers(WidgetTester tester) {
  final result = <BackdropFilterLayer>[];
  void visit(Layer layer) {
    if (layer is BackdropFilterLayer) result.add(layer);
    if (layer is ContainerLayer) {
      for (
        var child = layer.firstChild;
        child != null;
        child = child.nextSibling
      ) {
        visit(child);
      }
    }
  }

  visit(tester.binding.renderViews.single.debugLayer!);
  return result;
}

/// Clips to the glass's bounds inset by [inset] on every side.
class _InsetClipper extends CustomClipper<RRect> {
  const _InsetClipper(this.inset);

  final double inset;

  @override
  RRect getClip(Size size) => RRect.fromRectAndRadius(
    (Offset.zero & size).deflate(inset),
    const Radius.circular(8),
  );

  @override
  bool shouldReclip(_InsetClipper oldClipper) => oldClipper.inset != inset;
}

/// Black glass scene: a 120x80 liquid card in the middle of a 200x200 black
/// background, optionally rotated by [angle] around its centre.
Widget _scene({
  double angle = 0,
  Key? boundary,
  BorderRadius? borderRadius,
  CustomClipper<RRect>? clipper,
  bool grouped = false,
}) {
  return RepaintBoundary(
    key: boundary,
    child: ColoredBox(
      color: Colors.black,
      child: Center(
        child: Transform.rotate(
          angle: angle,
          child: const SizedBox(width: 120, height: 80).asGlass(
            clipBorderRadius: borderRadius ?? BorderRadius.circular(16),
            clipper: clipper,
            liquid: LiquidGlass.clear,
            grouped: grouped,
          ),
        ),
      ),
    ),
  );
}

/// Renders the boundary with [key] and returns its RGBA bytes and width.
Future<(ByteData, int)> _capture(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    final width = image.width;
    image.dispose();
    return (bytes!, width);
  }))!;
}

/// The red channel (0-255) of the pixel at ([x], [y]).
int _red((ByteData, int) image, double x, double y) {
  final (bytes, width) = image;
  return bytes.getUint8((y.floor() * width + x.floor()) * 4);
}

void main() {
  setUpAll(_bundleShaderUnderPackageKey);

  // CI sets this so the Impeller step can't pass by skipping everything.
  test(
    'shader filters are supported',
    skip: Platform.environment['GLASS_REQUIRE_SHADER'] != '1',
    () => expect(ui.ImageFilter.isShaderFilterSupported, isTrue),
  );

  testWidgets(
    'uses the shader instead of a plain BackdropFilter',
    skip: _skip,
    (tester) async {
      await _pumpLive(tester, _scene());

      expect(find.byType(BackdropFilter), findsNothing);
      final layers = _backdropLayers(tester);
      expect(layers, hasLength(1));
      expect(layers.single.filter, isNotNull);
    },
  );

  testWidgets('draws the rim inside the edge', skip: _skip, (tester) async {
    const key = Key('boundary');
    await _pumpLive(tester, _scene(boundary: key));
    final image = await _capture(tester, key);

    // The card spans x 40-160 and y 60-140. Over black, the inside is dark
    // and the first pixel inside the edge is the bright rim. (Its exact
    // brightness differs between Flutter versions.)
    final inside = _red(image, 100, 100);
    expect(inside, lessThan(40));
    expect(_red(image, 100, 60.5), greaterThan(inside + 50));
    expect(_red(image, 40.5, 100), greaterThan(inside + 50));
    expect(_red(image, 100, 58.5), lessThan(10)); // outside
  });

  testWidgets(
    'draws the same when it shares the backdrop of a BackdropGroup',
    skip: _skip,
    (tester) async {
      const key = Key('boundary');
      await _pumpLive(tester, _scene(boundary: key));
      final ungrouped = await _capture(tester, key);
      await _pumpLive(
        tester,
        BackdropGroup(child: _scene(boundary: key, grouped: true)),
      );
      final grouped = await _capture(tester, key);

      for (final (x, y) in [(100.0, 100.0), (100.0, 60.5), (40.5, 100.0)]) {
        expect(
          _red(grouped, x, y),
          closeTo(_red(ungrouped, x, y), 2),
          reason: 'at ($x, $y)',
        );
      }
      expect(
        _red(grouped, 100, 60.5),
        greaterThan(_red(grouped, 100, 100) + 50),
      );
    },
  );

  testWidgets('follows per-corner radii', skip: _skip, (tester) async {
    const key = Key('boundary');
    await _pumpLive(
      tester,
      _scene(
        boundary: key,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30)),
      ),
    );
    final image = await _capture(tester, key);

    // Only the top-left corner is round. The top-right corner (x 160, y 60)
    // is sharp, so a point 9 px inside both of its edges is not on the rim
    // (with a 30 px radius there, it would be).
    final inside = _red(image, 100, 100);
    expect(_red(image, 150.9, 69.1), lessThan(inside + 20));
    expect(_red(image, 159.5, 69.1), greaterThan(inside + 50)); // right edge
    expect(_red(image, 40.5, 60.5), lessThan(10)); // clipped round corner
  });

  testWidgets('follows a custom clipper', skip: _skip, (tester) async {
    const key = Key('boundary');
    await _pumpLive(
      tester,
      _scene(boundary: key, clipper: const _InsetClipper(10)),
    );
    final image = await _capture(tester, key);

    // The clipper insets the card by 10 px, so its left edge is at x 50.
    final inside = _red(image, 100, 100);
    expect(_red(image, 50.5, 100), greaterThan(inside + 50));
    expect(_red(image, 48.5, 100), lessThan(10)); // outside
  });

  testWidgets('draws the rim along rotated edges', skip: _skip, (tester) async {
    const key = Key('boundary');
    const angle = math.pi / 6;
    await _pumpLive(tester, _scene(angle: angle, boundary: key));
    final image = await _capture(tester, key);

    // Just inside the middle of the rotated top edge (local (60, 0.5) from
    // the card centre's frame), and the card's centre.
    Offset screen(double lx, double ly) {
      final x = lx - 60, y = ly - 40;
      return Offset(
        100 + x * math.cos(angle) - y * math.sin(angle),
        100 + x * math.sin(angle) + y * math.cos(angle),
      );
    }

    final rim = screen(60, 0.6), centre = screen(60, 40);
    final inside = _red(image, centre.dx, centre.dy);
    expect(inside, lessThan(40));
    expect(_red(image, rim.dx, rim.dy), greaterThan(inside + 40));
  });

  testWidgets(
    'rebuilds the filter when an ancestor moves the glass',
    skip: _skip,
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pumpLive(
        tester,
        SingleChildScrollView(
          controller: controller,
          child: SizedBox(
            height: 1000,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                // Its own repaint boundary: scrolling moves it without
                // repainting it.
                child: RepaintBoundary(
                  child: const SizedBox(
                    width: 100,
                    height: 60,
                  ).asGlass(liquid: LiquidGlass.clear),
                ),
              ),
            ),
          ),
        ),
      );
      final before = _backdropLayers(tester).single.filter;

      await tester.pump();
      expect(
        _backdropLayers(tester).single.filter,
        same(before),
        reason: 'nothing moved, so the filter is reused',
      );

      controller.jumpTo(100);
      await tester.pump();
      expect(_backdropLayers(tester).single.filter, isNot(same(before)));
    },
  );
}
