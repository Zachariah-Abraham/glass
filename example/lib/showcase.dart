// Flutter 3.50 deprecates material.dart; material_ui does not exist on the minimum Flutter 3.29.
// ignore_for_file: deprecated_member_use
// A scripted, hands-free liquid glass scene for screen recordings. Everything
// moves on a 12 second loop, so a recording of one cycle loops seamlessly.
// Run it with `flutter run -t lib/showcase.dart` on an Impeller target (iOS,
// Android or macOS); on web and Skia the glass falls back to plain blur.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

void main() => runApp(const ShowcaseApp());

/// The showcase app.
class ShowcaseApp extends StatelessWidget {
  /// Creates the showcase app.
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'glass showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const Showcase(),
    );
  }
}

/// The scene: an endless feed behind a lens, a morphing card and a tab bar.
class Showcase extends StatefulWidget {
  /// Creates the scene.
  const Showcase({super.key});

  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(time: _time),
          SafeArea(
            child: Stack(
              children: [
                const Positioned(left: 20, right: 20, top: 8, child: _Header()),
                _Lens(time: _time),
                _MorphingCard(time: _time),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 12,
                  child: _TabBar(time: _time),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Moving colour blobs under an endlessly scrolling feed of words and tiles.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.time});

  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _BlobPainter(time)),
          AnimatedBuilder(
            animation: time,
            builder:
                (context, child) => ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    maxHeight: double.infinity,
                    child: Transform.translate(
                      // One full feed period per cycle, so the loop is seamless.
                      offset: Offset(0, -time.value * _Feed.period),
                      child: child,
                    ),
                  ),
                ),
            child: const Column(children: [_Feed(), _Feed(), _Feed()]),
          ),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.time) : super(repaint: time);

  final Animation<double> time;

  static const _colors = [
    Color(0xFF6A3CFF),
    Color(0xFFFF3D8B),
    Color(0xFFFF9F1C),
    Color(0xFF00D1B2),
    Color(0xFF2F80ED),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0A2A), Color(0xFF1A0B2E), Color(0xFF051B2C)],
        ).createShader(Offset.zero & size),
    );
    final a = time.value * 2 * math.pi;
    for (var i = 0; i < _colors.length; i++) {
      final phase = i * 2 * math.pi / _colors.length;
      final center = Offset(
        size.width * (0.5 + 0.38 * math.sin(a + phase)),
        size.height * (0.5 + 0.4 * math.cos(2 * a + phase * 1.3)),
      );
      canvas.drawCircle(
        center,
        size.width * 0.32,
        Paint()
          ..color = _colors[i].withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => false;
}

/// One period of the feed. Every row has a fixed height so [period] is exact.
class _Feed extends StatelessWidget {
  const _Feed();

  static const _rows = <Widget>[
    _Word('REFRACTION'),
    _Tiles(0),
    _Stripes(),
    _Word('RIM LIGHT'),
    _Tiles(1),
    _Word('FLUTTER'),
    _Stripes(),
    _Tiles(2),
    _Word('LIQUID'),
  ];

  static const _rowHeight = 120.0;

  /// The height of one feed.
  static const period = _rowHeight * 9;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows) SizedBox(height: _rowHeight, child: row),
      ],
    );
  }
}

class _Word extends StatelessWidget {
  const _Word(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 76,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles(this.seed);

  final int seed;

  static const _palette = [
    [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
    [Color(0xFF6BCB77), Color(0xFF4D96FF)],
    [Color(0xFFB983FF), Color(0xFFFF6FB5)],
    [Color(0xFF00C9A7), Color(0xFF845EC2)],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _palette[(seed + i) % _palette.length],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stripes extends StatelessWidget {
  const _Stripes();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StripePainter());
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = 6;
    for (var x = -size.height; x < size.width; x += 22) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 76,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text(
              'glass',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            Text(
              'liquid glass\nfor Flutter',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).asGlass(
      clipBorderRadius: BorderRadius.circular(38),
      liquid: LiquidGlass.regular,
    );
  }
}

/// A clear round lens gliding over the feed on a figure-eight.
class _Lens extends StatelessWidget {
  const _Lens({required this.time});

  final Animation<double> time;

  static const _size = 150.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: time,
      builder: (context, child) {
        final area = MediaQuery.sizeOf(context);
        final a = time.value * 2 * math.pi;
        return Positioned(
          left: area.width / 2 - _size / 2 + area.width * 0.26 * math.sin(a),
          top: area.height * 0.3 - _size / 2 + 90 * math.sin(2 * a),
          child: child!,
        );
      },
      child: const SizedBox.square(dimension: _size).asGlass(
        clipBorderRadius: BorderRadius.circular(_size / 2),
        liquid: LiquidGlass.clear,
      ),
    );
  }
}

/// A clear card that breathes between a pill and a tall card.
class _MorphingCard extends StatelessWidget {
  const _MorphingCard({required this.time});

  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: time,
      builder: (context, _) {
        final area = MediaQuery.sizeOf(context);
        // Two breaths per cycle, eased at both ends.
        final s = (1 - math.cos(time.value * 4 * math.pi)) / 2;
        final width = 260 + 80 * s;
        final height = 88 + 112 * s;
        return Positioned(
          left: (area.width - width) / 2,
          top: area.height * 0.62 - height / 2,
          child: SizedBox(width: width, height: height).asGlass(
            clipBorderRadius: BorderRadius.circular(44 - 12 * s),
            liquid: LiquidGlass.clear,
          ),
        );
      },
    );
  }
}

/// A regular glass tab bar with a clear bubble hopping between its icons.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.time});

  final Animation<double> time;

  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
  ];

  static const _height = 72.0;
  static const _bubble = 64.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / _icons.length;
          return Stack(
            fit: StackFit.expand,
            children: [
              Row(
                children: [
                  for (final icon in _icons)
                    Expanded(
                      child: Icon(icon, size: 30, color: Colors.black87),
                    ),
                ],
              ).asGlass(
                clipBorderRadius: BorderRadius.circular(_height / 2),
                liquid: LiquidGlass.regular,
              ),
              AnimatedBuilder(
                animation: time,
                builder: (context, child) {
                  // Six hops per cycle: 0, 1, 2, 3, 2, 1, then back to 0.
                  final hops = time.value * 6;
                  const stops = [0, 1, 2, 3, 2, 1, 0];
                  final from = stops[hops.floor() % 6];
                  final to = stops[hops.floor() % 6 + 1];
                  final f = Curves.easeOutBack.transform(
                    ((hops - hops.floor()) / 0.4).clamp(0.0, 1.0),
                  );
                  final position = from + (to - from) * f;
                  return Positioned(
                    left: slot * position + (slot - _bubble * 1.25) / 2,
                    top: (_height - _bubble) / 2,
                    child: child!,
                  );
                },
                child: const SizedBox(
                  width: _bubble * 1.25,
                  height: _bubble,
                ).asGlass(
                  clipBorderRadius: BorderRadius.circular(_bubble / 2),
                  liquid: LiquidGlass.clear,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
