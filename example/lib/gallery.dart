// Flutter 3.50 deprecates material.dart; material_ui does not exist on the minimum Flutter 3.29.
// ignore_for_file: deprecated_member_use
// A gallery of glass widgets over an animated background, for checking how
// they look on each platform. Run it with `flutter run -t lib/gallery.dart`.
//
// The liquid stories refract and draw a rim only on Impeller (iOS, Android and
// other Impeller targets). On web and Skia, `liquid:` falls back to plain glass.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:glass/glass.dart';

void main() => runApp(const GalleryApp());

/// The gallery app.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery app.
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'glass gallery',
      debugShowCheckedModeBanner: false,
      // Let a mouse drag scroll too, so desktop and web feel like a phone.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: ui.PointerDeviceKind.values.toSet(),
      ),
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const Gallery(),
    );
  }
}

class _Story {
  const _Story(this.title, this.description, this.builder);

  final String title;
  final String description;
  final Widget Function(Animation<double> time) builder;
}

final _stories = <_Story>[
  _Story(
    'Plain glass',
    'asGlass() variants: default, no frost, tinted, no tint, strong blur.',
    (_) => const _PlainStory(),
  ),
  _Story(
    'Liquid clear',
    'LiquidGlass.clear: transparent, bent edges and a light rim.',
    (_) => const _ShapesStory(liquid: LiquidGlass.clear),
  ),
  _Story(
    'Liquid regular',
    'LiquidGlass.regular: light frost, saturated, soft shadow.',
    (_) => const _ShapesStory(liquid: LiquidGlass.regular),
  ),
  _Story(
    'Side by side',
    'The same card as plain glass, liquid clear and liquid regular.',
    (_) => const _CompareStory(),
  ),
  _Story(
    'Drag me',
    'Drag the pills around. Watch the edges bend what is behind them.',
    (_) => const _DragStory(),
  ),
  _Story(
    'Transforms',
    'Liquid glass under rotation, skew and perspective.',
    (time) => _TransformStory(time: time),
  ),
  _Story(
    'Scrolling list',
    'Liquid cards inside a scroll view. Scroll it.',
    (_) => const _ScrollStory(),
  ),
  _Story(
    'Playground',
    'Tune LiquidGlass with sliders.',
    (_) => const _PlaygroundStory(),
  ),
];

/// The gallery: a story picker over an animated background.
class Gallery extends StatefulWidget {
  /// Creates the gallery.
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();
  var _index = 0;

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  void _toggleTime() {
    setState(() => _time.isAnimating ? _time.stop() : _time.repeat());
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_index];
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              for (final (i, s) in _stories.indexed)
                ListTile(
                  title: Text(s.title),
                  subtitle: Text(s.description),
                  selected: i == _index,
                  onTap: () {
                    setState(() => _index = i);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _Background(time: _time)),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 72, bottom: 72),
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: story.builder(_time),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _TopBar(story: story, rendererNote: _rendererNote),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _BottomBar(
                  paused: !_time.isAnimating,
                  onPrevious:
                      () => setState(
                        () => _index = (_index - 1) % _stories.length,
                      ),
                  onNext:
                      () => setState(
                        () => _index = (_index + 1) % _stories.length,
                      ),
                  onPause: _toggleTime,
                  label: '${_index + 1} / ${_stories.length}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _rendererNote =
      ui.ImageFilter.isShaderFilterSupported
          ? 'Impeller: liquid shader on'
          : 'No shader filters: liquid falls back to plain glass';
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.story, required this.rendererNote});

  final _Story story;
  final String rendererNote;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                tooltip: 'Stories',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ).asGlass(
                clipBorderRadius: BorderRadius.circular(24),
                liquid: LiquidGlass.regular,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${story.description}\n$rendererNote',
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ).asGlass(
            clipBorderRadius: BorderRadius.circular(20),
            liquid: LiquidGlass.regular,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.paused,
    required this.onPrevious,
    required this.onNext,
    required this.onPause,
    required this.label,
  });

  final bool paused;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPause;
  final String label;

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.black87;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: iconColor),
            tooltip: 'Previous story',
            onPressed: onPrevious,
          ),
          Text(label, style: const TextStyle(color: iconColor)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: iconColor),
            tooltip: 'Next story',
            onPressed: onNext,
          ),
          IconButton(
            icon: Icon(
              paused ? Icons.play_arrow : Icons.pause,
              color: iconColor,
            ),
            tooltip: paused ? 'Animate background' : 'Pause background',
            onPressed: onPause,
          ),
        ],
      ).asGlass(
        clipBorderRadius: BorderRadius.circular(28),
        liquid: LiquidGlass.regular,
      ),
    );
  }
}

/// Animated background: drifting coloured blobs, stripes and text.
class _Background extends StatelessWidget {
  const _Background({required this.time});

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
                      offset: Offset(0, -_scrollOffset(time.value)),
                      child: child,
                    ),
                  ),
                ),
            child: const _BackgroundText(),
          ),
        ],
      ),
    );
  }

  /// Scrolls the text up and back down over a cycle.
  static double _scrollOffset(double t) =>
      (1 - math.cos(t * 2 * math.pi)) / 2 * 900;
}

class _BackgroundText extends StatelessWidget {
  const _BackgroundText();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Glass',
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          for (var i = 0; i < 30; i++)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'Line ${i + 1}: the quick brown fox jumps over the lazy dog.',
                style: TextStyle(
                  fontSize: i.isEven ? 22 : 16,
                  color: Colors.white.withValues(alpha: i.isEven ? 0.95 : 0.7),
                  fontWeight: i % 3 == 0 ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
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
    Color(0xFFFF3D7F),
    Color(0xFFFFB300),
    Color(0xFF00E5FF),
    Color(0xFF7C4DFF),
    Color(0xFF00E676),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ).createShader(Offset.zero & size),
    );
    // Diagonal stripes, so bending at the edges is easy to see.
    final stripe =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 6;
    final shift = time.value * 400 % 40;
    for (var x = -size.height; x < size.width; x += 40) {
      canvas.drawLine(
        Offset(x + shift, size.height),
        Offset(x + shift + size.height, 0),
        stripe,
      );
    }
    final t = time.value * 2 * math.pi;
    for (final (i, color) in _colors.indexed) {
      final center = Offset(
        size.width * (0.5 + 0.38 * math.sin(t * (i + 1) + i)),
        size.height * (0.5 + 0.38 * math.cos(t * (i % 3 + 1) + 2 * i)),
      );
      canvas.drawCircle(
        center,
        math.min(size.width, size.height) * 0.16,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => oldDelegate.time != time;
}

/// A centred, scrollable column for stories with several items.
class _Column extends StatelessWidget {
  const _Column({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: child,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A label for the glass it sits on.
class _Label extends StatelessWidget {
  const _Label(this.text, {this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: dark ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          shadows:
              dark
                  ? null
                  : const [Shadow(blurRadius: 4, color: Colors.black54)],
        ),
      ),
    );
  }
}

class _PlainStory extends StatelessWidget {
  const _PlainStory();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    Widget card(String label) => SizedBox(height: 90, child: _Label(label));
    return _Column(
      children: [
        card('Default').asGlass(clipBorderRadius: radius),
        card(
          'frosted: false',
        ).asGlass(clipBorderRadius: radius, frosted: false),
        card(
          'tintColor: Colors.cyan',
        ).asGlass(clipBorderRadius: radius, tintColor: Colors.cyan),
        card(
          'tintColor: Colors.transparent',
        ).asGlass(clipBorderRadius: radius, tintColor: Colors.transparent),
        card(
          'blurX/blurY: 25',
        ).asGlass(clipBorderRadius: radius, blurX: 25, blurY: 25),
        card(
          'blurX: 20, blurY: 0',
        ).asGlass(clipBorderRadius: radius, blurX: 20, blurY: 0),
      ],
    );
  }
}

class _ShapesStory extends StatelessWidget {
  const _ShapesStory({required this.liquid});

  final LiquidGlass liquid;

  @override
  Widget build(BuildContext context) {
    final dark = identical(liquid, LiquidGlass.regular);
    return _Column(
      children: [
        SizedBox(
          height: 180,
          child: _Label('Card, radius 32', dark: dark),
        ).asGlass(clipBorderRadius: BorderRadius.circular(32), liquid: liquid),
        SizedBox(
          height: 80,
          child: _Label('Pill, radius 40', dark: dark),
        ).asGlass(clipBorderRadius: BorderRadius.circular(40), liquid: liquid),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final icon in [Icons.play_arrow, Icons.favorite, Icons.share])
              SizedBox(
                width: 64,
                height: 64,
                child: Icon(icon, color: dark ? Colors.black87 : Colors.white),
              ).asGlass(
                clipBorderRadius: BorderRadius.circular(32),
                liquid: liquid,
              ),
          ],
        ),
        SizedBox(
          height: 120,
          child: _Label('Square corners', dark: dark),
        ).asGlass(liquid: liquid),
      ],
    );
  }
}

class _CompareStory extends StatelessWidget {
  const _CompareStory();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return _Column(
      children: [
        const SizedBox(
          height: 130,
          child: _Label('Plain asGlass()'),
        ).asGlass(clipBorderRadius: radius),
        const SizedBox(
          height: 130,
          child: _Label('LiquidGlass.clear'),
        ).asGlass(clipBorderRadius: radius, liquid: LiquidGlass.clear),
        const SizedBox(
          height: 130,
          child: _Label('LiquidGlass.regular', dark: true),
        ).asGlass(clipBorderRadius: radius, liquid: LiquidGlass.regular),
      ],
    );
  }
}

class _DragStory extends StatefulWidget {
  const _DragStory();

  @override
  State<_DragStory> createState() => _DragStoryState();
}

class _DragStoryState extends State<_DragStory> {
  var _clear = const Offset(30, 40);
  var _regular = const Offset(60, 220);

  @override
  Widget build(BuildContext context) {
    Widget pill(
      Offset at,
      LiquidGlass liquid,
      String label,
      bool dark,
      ValueChanged<Offset> move,
    ) {
      return Positioned(
        left: at.dx,
        top: at.dy,
        width: 240,
        height: 80,
        child: GestureDetector(
          onPanUpdate: (details) => move(details.delta),
          child: SizedBox.expand(child: _Label(label, dark: dark)).asGlass(
            clipBorderRadius: BorderRadius.circular(40),
            liquid: liquid,
          ),
        ),
      );
    }

    return Stack(
      children: [
        pill(
          _clear,
          LiquidGlass.clear,
          'Drag me (clear)',
          false,
          (d) => setState(() => _clear += d),
        ),
        pill(
          _regular,
          LiquidGlass.regular,
          'Drag me (regular)',
          true,
          (d) => setState(() => _regular += d),
        ),
      ],
    );
  }
}

class _TransformStory extends StatelessWidget {
  const _TransformStory({required this.time});

  final Animation<double> time;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: time,
      builder: (context, _) {
        final t = time.value * 2 * math.pi;
        Widget card(String label) =>
            SizedBox(width: 200, height: 110, child: _Label(label)).asGlass(
              clipBorderRadius: BorderRadius.circular(24),
              liquid: LiquidGlass.clear,
            );
        return _Column(
          children: [
            Center(
              child: Transform.rotate(angle: t * 4, child: card('Rotating')),
            ),
            Center(
              child: Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()..setEntry(0, 1, 0.4 * math.sin(t * 6)),
                child: card('Skewed'),
              ),
            ),
            Center(
              child: Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY(0.8 * math.sin(t * 5)),
                child: card('Perspective'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrollStory extends StatelessWidget {
  const _ScrollStory();

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      // Material 3's stretch overscroll hides backdrop filters (see README).
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: 20,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final regular = i % 3 == 2;
          return SizedBox(
            height: 72,
            child: _Label(
              'Item ${i + 1} (${regular ? 'regular' : 'clear'})',
              dark: regular,
            ),
          ).asGlass(
            clipBorderRadius: BorderRadius.circular(36),
            liquid: regular ? LiquidGlass.regular : LiquidGlass.clear,
          );
        },
      ),
    );
  }
}

class _PlaygroundStory extends StatefulWidget {
  const _PlaygroundStory();

  @override
  State<_PlaygroundStory> createState() => _PlaygroundStoryState();
}

class _PlaygroundStoryState extends State<_PlaygroundStory> {
  var _blur = 3.0;
  var _refraction = 1.0;
  var _highlight = 1.0;
  var _tintStrength = 0.1;
  var _saturation = 1.0;
  var _radius = 40.0;

  @override
  Widget build(BuildContext context) {
    final liquid = LiquidGlass(
      blur: _blur,
      refraction: _refraction,
      highlight: _highlight,
      tintStrength: _tintStrength,
      saturation: _saturation,
    );
    Widget slider(
      String label,
      double value,
      double max,
      ValueChanged<double> onChanged,
    ) {
      return Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label ${value.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
          Expanded(child: Slider(value: value, max: max, onChanged: onChanged)),
        ],
      );
    }

    return _Column(
      children: [
        const SizedBox(height: 160, child: _Label('Your glass')).asGlass(
          clipBorderRadius: BorderRadius.circular(_radius),
          liquid: liquid,
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              slider('blur', _blur, 20, (v) => setState(() => _blur = v)),
              slider(
                'refraction',
                _refraction,
                3,
                (v) => setState(() => _refraction = v),
              ),
              slider(
                'highlight',
                _highlight,
                3,
                (v) => setState(() => _highlight = v),
              ),
              slider(
                'tint',
                _tintStrength,
                1,
                (v) => setState(() => _tintStrength = v),
              ),
              slider(
                'saturation',
                _saturation,
                3,
                (v) => setState(() => _saturation = v),
              ),
              slider('radius', _radius, 80, (v) => setState(() => _radius = v)),
            ],
          ),
        ).asGlass(
          clipBorderRadius: BorderRadius.circular(24),
          liquid: LiquidGlass.regular,
        ),
      ],
    );
  }
}
