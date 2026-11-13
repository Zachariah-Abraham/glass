// Flutter 3.50 deprecates material.dart; material_ui does not exist on the minimum Flutter 3.29.
// ignore_for_file: deprecated_member_use
// LiquidGlass.precache. In its own file because the loaded shader is cached
// for the whole test isolate, and the first test needs it not loaded yet.
// (Without precache, the first frame is plain blur: see `_pumpLive` in
// liquid_shader_test.dart.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass/glass.dart';

/// See `_bundleShaderUnderPackageKey` in liquid_shader_test.dart.
void _bundleShaderUnderPackageKey() {
  const dir = 'build/unit_test_assets';
  final source = File('$dir/shaders/liquid_glass.frag');
  final target = File('$dir/packages/glass/shaders/liquid_glass.frag');
  if (source.existsSync()) {
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
  }
}

Widget _glass() => Directionality(
  textDirection: TextDirection.ltr,
  child: const SizedBox(
    width: 100,
    height: 60,
  ).asGlass(liquid: LiquidGlass.regular),
);

void main() {
  setUpAll(_bundleShaderUnderPackageKey);

  testWidgets('after precache the first frame uses the shader', (tester) async {
    await tester.runAsync(LiquidGlass.precache);
    await tester.pumpWidget(_glass());
    expect(find.byType(BackdropFilter), findsNothing);
  }, skip: !ui.ImageFilter.isShaderFilterSupported);

  testWidgets('precache completes and keeps the fallback without shaders', (
    tester,
  ) async {
    await tester.runAsync(LiquidGlass.precache);
    await tester.runAsync(LiquidGlass.precache); // repeat calls are fine
    await tester.pumpWidget(_glass());
    expect(find.byType(BackdropFilter), findsOneWidget);
  }, skip: ui.ImageFilter.isShaderFilterSupported);
}
