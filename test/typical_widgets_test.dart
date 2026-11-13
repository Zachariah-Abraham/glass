// Flutter 3.50 deprecates material.dart; material_ui does not exist on the minimum Flutter 3.29.
// ignore_for_file: deprecated_member_use
// asGlass on everyday widgets: it must not change their size, input or
// semantics, with plain glass and with liquid glass. With
// `flutter test --enable-impeller` the liquid cases run the live shader path,
// otherwise its plain blur fallback.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass/glass.dart';

final _shaders = ui.ImageFilter.isShaderFilterSupported;

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

/// A 1x1 PNG, so Image.memory needs no assets or network.
final _pixel = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Everyday widgets, by name. Each builder gets a callback for taps.
final _widgets = <String, Widget Function(VoidCallback)>{
  'Text': (_) => const Text('Hello'),
  'Icon': (_) => const Icon(Icons.star),
  'Image.memory': (_) => Image.memory(_pixel, width: 40, height: 30),
  'FlutterLogo': (_) => const FlutterLogo(size: 48),
  'ElevatedButton':
      (tap) => ElevatedButton(onPressed: tap, child: const Text('Go')),
  'TextButton': (tap) => TextButton(onPressed: tap, child: const Text('Go')),
  'IconButton':
      (tap) => IconButton(onPressed: tap, icon: const Icon(Icons.add)),
  'FloatingActionButton':
      (tap) =>
          FloatingActionButton(onPressed: tap, child: const Icon(Icons.add)),
  'InkWell': (tap) => InkWell(onTap: tap, child: const Text('Go')),
  'GestureDetector':
      (tap) => GestureDetector(onTap: tap, child: const Text('Go')),
  'ListTile':
      (tap) => ListTile(
        onTap: tap,
        leading: const Icon(Icons.person),
        title: const Text('Go'),
      ),
  'Card':
      (_) => const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('Card')),
      ),
  'Chip': (_) => const Chip(label: Text('Chip')),
  'Switch': (tap) => Switch(value: false, onChanged: (_) => tap()),
  'Checkbox': (tap) => Checkbox(value: false, onChanged: (_) => tap()),
  'Slider': (tap) => Slider(value: 0.5, onChanged: (_) => tap()),
  'TextField': (_) => const SizedBox(width: 200, child: TextField()),
  'CircularProgressIndicator':
      (_) => const CircularProgressIndicator(value: 0.4),
  'Row':
      (_) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.home), Text('Home')],
      ),
  'Column':
      (_) => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text('One'), Text('Two')],
      ),
  'Wrap':
      (_) => const Wrap(
        children: [Chip(label: Text('a')), Chip(label: Text('b'))],
      ),
  'Stack':
      (_) =>
          const Stack(children: [SizedBox(width: 60, height: 40), Text('top')]),
  'ListView':
      (_) => SizedBox(
        width: 200,
        height: 150,
        child: ListView(
          children: [for (var i = 0; i < 20; i++) Text('Row $i')],
        ),
      ),
  'NavigationBar':
      (tap) => SizedBox(
        width: 360,
        child: NavigationBar(
          onDestinationSelected: (_) => tap(),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          ],
        ),
      ),
  'AppBar':
      (_) => SizedBox(width: 360, child: AppBar(title: const Text('Title'))),
  'SizedBox.shrink': (_) => const SizedBox.shrink(),
};

/// Widgets with an onTap/onChanged, and where to tap them.
const _tappable = {
  'ElevatedButton',
  'TextButton',
  'IconButton',
  'FloatingActionButton',
  'InkWell',
  'GestureDetector',
  'ListTile',
  'Switch',
  'Checkbox',
  'Slider',
  'NavigationBar',
};

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo, Colors.orange]),
      ),
      child: Center(child: child),
    ),
  ),
);

/// The app's semantics tree, without the ids that differ between pumps.
String _semanticsTree(WidgetTester tester) => tester
    .binding
    .renderViews
    .single
    .owner!
    .semanticsOwner!
    .rootSemanticsNode!
    .toStringDeep(childOrder: DebugSemanticsDumpOrder.inverseHitTest)
    .replaceAll(RegExp(r'#[0-9a-f]+'), '#');

/// Waits until a liquid glass uses the shader (only possible on Impeller).
Future<void> _waitForShader(WidgetTester tester) async {
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
}

void main() {
  setUpAll(_bundleShaderUnderPackageKey);

  for (final liquid in [null, LiquidGlass.clear, LiquidGlass.regular]) {
    final mode =
        liquid == null
            ? 'plain'
            : liquid == LiquidGlass.clear
            ? 'liquid clear'
            : 'liquid regular';
    group('$mode glass', () {
      for (final MapEntry(key: name, value: build) in _widgets.entries) {
        testWidgets(name, (tester) async {
          const key = Key('subject');
          var taps = 0;
          void tap() => taps++;

          // Reference: the bare widget.
          await tester.pumpWidget(
            _app(KeyedSubtree(key: key, child: build(tap))),
          );
          await tester.pumpAndSettle();
          final size = tester.getSize(find.byKey(key));
          final semantics = tester.ensureSemantics();
          final bareTree = _semanticsTree(tester);

          await tester.pumpWidget(
            _app(
              KeyedSubtree(
                key: key,
                child: build(tap).asGlass(
                  clipBorderRadius: BorderRadius.circular(12),
                  liquid: liquid,
                ),
              ),
            ),
          );
          if (liquid != null && _shaders) {
            await _waitForShader(tester);
            expect(
              find.byType(BackdropFilter),
              findsNothing,
              reason: 'shader not live',
            );
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byKey(key)),
            size,
            reason: 'layout changed',
          );

          final glassTree = _semanticsTree(tester);
          expect(glassTree, bareTree, reason: 'semantics changed');
          semantics.dispose();

          if (_tappable.contains(name)) {
            // A slider only reports a change, so tap away from its value.
            final at =
                name == 'Slider'
                    ? Alignment.centerLeft * 0.8
                    : Alignment.center;
            final rect = tester.getRect(find.byKey(key));
            await tester.tapAt(at.withinRect(rect));
            await tester.pumpAndSettle();
            expect(
              taps,
              greaterThan(0),
              reason: 'tap did not reach the widget',
            );
          }
          if (name == 'TextField') {
            await tester.enterText(find.byType(TextField), 'typed');
            expect(find.text('typed'), findsOneWidget);
          }
          if (name == 'ListView') {
            await tester.drag(find.byType(ListView), const Offset(0, -300));
            await tester.pumpAndSettle();
            expect(find.text('Row 0'), findsNothing, reason: 'did not scroll');
          }
        });
      }

      testWidgets('each row of a scrolling ListView', (tester) async {
        await tester.pumpWidget(
          _app(
            ListView(
              children: [
                for (var i = 0; i < 30; i++)
                  ListTile(title: Text('Row $i')).asGlass(liquid: liquid),
              ],
            ),
          ),
        );
        if (liquid != null && _shaders) await _waitForShader(tester);
        await tester.fling(find.byType(ListView), const Offset(0, -800), 2000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Row 0'), findsNothing);
      });

      testWidgets('inside Transform, Opacity and a Hero route push', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: Center(
                      child: Opacity(
                        opacity: 0.7,
                        child: Transform.rotate(
                          angle: 0.3,
                          child: Hero(
                            tag: 'h',
                            child: ElevatedButton(
                              onPressed:
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder:
                                          (_) => const Scaffold(
                                            body: Hero(
                                              tag: 'h',
                                              child: Text('Next'),
                                            ),
                                          ),
                                    ),
                                  ),
                              child: const Text('Open'),
                            ).asGlass(liquid: liquid),
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        );
        if (liquid != null && _shaders) await _waitForShader(tester);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Next'), findsOneWidget);
      });
    });
  }
}
