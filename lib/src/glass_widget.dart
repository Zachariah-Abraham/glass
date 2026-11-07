import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';

/// Settings for the liquid glass look: the backdrop bends near the edges of
/// the glass, which has a thin light rim.
///
/// Pass it to [GlassWidget.asGlass] as `liquid`, usually one of the presets
/// [LiquidGlass.regular] or [LiquidGlass.clear], optionally adjusted with
/// [copyWith] (for example `LiquidGlass.regular.copyWith(tintColor: Colors.blue)`).
///
/// The preset supplies the blur, tint and frost. Values passed to `asGlass`
/// directly (`blurX`, `blurY`, `tintColor`, `frosted`) take precedence.
///
/// The bending needs the Impeller renderer. Elsewhere (for example on web) the
/// glass keeps its blur and tint but doesn't bend the backdrop.
///
/// Only uniform corner radii are supported: the shape is a rounded rectangle
/// with the top-left radius of `clipBorderRadius`, and `clipper` is ignored by
/// the bending.
class LiquidGlass {
  /// Creates liquid glass settings.
  ///
  /// * [blur]: Blur sigma along both axes, defaults to 3.0 (1.6 for [clear]).
  /// * [tintColor]: Tint color of the glass, defaults to [Colors.black].
  /// * [tintStrength]: Opacity of the tint from 0 to 1, defaults to 0.15.
  /// * [refraction]: How strongly the edges bend the backdrop, 0 for none.
  ///   1.0, the default, matches Apple's native glass.
  /// * [edgeWidth]: Width of the refracting edge band in logical pixels.
  ///   Defaults to null, which uses `min(20, 0.69 * R)` where R is half the
  ///   shorter side, as measured on Apple's glass.
  /// * [lift]: Brightness added to the blurred backdrop before the tint, from
  ///   0 to 1 (0.075 is about 19 of 255), defaults to 0.
  /// * [midtoneLift]: Brightens the mid-tones of the blurred backdrop before
  ///   the tint (`x += midtoneLift * x * (1 - x)`), which makes the tinted
  ///   result slightly concave like Apple's `Glass.regular`. Defaults to 0
  ///   (linear).
  /// * [highlight]: Intensity of the rim, 1.0 (the default) matches Apple's
  ///   native glass, 0 hides it.
  /// * [shadow]: A soft shadow painted just outside the glass shape, null (the
  ///   default) for none. Only its color, `offset` and `blurRadius` are used.
  ///   It doesn't affect layout or hit testing and is painted outside the
  ///   glass's bounds, so an ancestor that clips can cut it off.
  const LiquidGlass({
    this.blur = 3.0,
    this.tintColor = Colors.white,
    this.tintStrength = 0.1,
    this.refraction = 1.0,
    this.edgeWidth,
    this.lift = 0.0,
    this.midtoneLift = 0.0,
    this.highlight = 1.0,
    this.shadow,
  });

  /// Frosted, mostly opaque glass with a light tint, like Apple's
  /// `Glass.regular`. Use it where legibility of content on the glass matters.
  static const regular = LiquidGlass(
    blur: 7.0,
    tintColor: Color(0xFFF2F8FB),
    tintStrength: 0.735,
    shadow: BoxShadow(
      color: Color(0x16000000),
      offset: Offset(0, 8),
      blurRadius: 30,
    ),
  );

  /// Highly transparent glass with a slight dark tint, like Apple's
  /// `Glass.clear`. Use it over rich media.
  static const clear = LiquidGlass(
    blur: 1.6,
    tintStrength: 0.0,
    lift: 0.0745,
    midtoneLift: 0.086,
  );

  /// Blur sigma along both axes.
  final double blur;

  /// Tint color of the glass.
  final Color tintColor;

  /// Opacity of the tint from 0 to 1.
  final double tintStrength;

  /// Strength of the edge refraction, 1.0 matches Apple's native glass.
  ///
  /// The backdrop is sampled from up to `3 * edgeWidth * refraction` logical
  /// pixels deeper inside the glass, only inward and never from outside it.
  final double refraction;

  /// Width of the refracting edge band in logical pixels, or null for
  /// `min(20, 0.69 * R)` with R half the shorter side.
  final double? edgeWidth;

  /// Brightness added to the blurred backdrop (before the tint), 0 for none.
  final double lift;

  /// Brightens the mid-tones of the blurred backdrop before the tint, 0 for
  /// a linear tint.
  final double midtoneLift;

  /// Intensity of the rim, 1.0 matches Apple's native glass.
  final double highlight;

  /// Soft shadow painted just outside the glass shape, or null for none.
  ///
  /// Only the color, `offset` and `blurRadius` are used. The shadow is clipped
  /// out of the glass itself, doesn't affect layout or hit testing, and can be
  /// cut off by an ancestor that clips.
  final BoxShadow? shadow;

  /// Returns a copy with the given fields replaced.
  LiquidGlass copyWith({
    double? blur,
    Color? tintColor,
    double? tintStrength,
    double? refraction,
    double? edgeWidth,
    double? lift,
    double? midtoneLift,
    double? highlight,
    BoxShadow? shadow,
  }) {
    return LiquidGlass(
      blur: blur ?? this.blur,
      tintColor: tintColor ?? this.tintColor,
      tintStrength: tintStrength ?? this.tintStrength,
      refraction: refraction ?? this.refraction,
      edgeWidth: edgeWidth ?? this.edgeWidth,
      lift: lift ?? this.lift,
      midtoneLift: midtoneLift ?? this.midtoneLift,
      highlight: highlight ?? this.highlight,
      shadow: shadow ?? this.shadow,
    );
  }
}

extension GlassWidget<T extends Widget> on T {
  /// .asGlass(): Converts the calling widget into a glass widget.
  ///
  /// Parameters:
  /// * [enabled]: Enable or disable all effects, defaults to true.
  /// * [blurX]: Amount of blur in the direction of the X axis, defaults to 10.0
  ///   (or the [liquid] preset's blur).
  /// * [blurY]: Amount of blur in the direction of the Y axis, defaults to 10.0
  ///   (or the [liquid] preset's blur).
  /// * [tintColor]: Tint color for the glass, defaults to Colors.white (or the
  ///   [liquid] preset's tint).
  /// * [frosted]: Whether this glass should be frosted or not, defaults to true
  ///   (false with [liquid]).
  /// * [clipBorderRadius]: The border radius of the rounded corners.
  ///   Values are clamped so that horizontal and vertical radii sums do not exceed width/height.
  ///   This value is ignored if clipper is non-null.
  /// * [clipBehavior]: How the glass is clipped, defaults to [Clip.antiAlias].
  /// * [clipBehaviour]: Deprecated misspelling of [clipBehavior]. Ignored if [clipBehavior] is set.
  /// * [tileMode]: Defines what happens at the edge of a gradient or the sampling of a source image in an [ImageFilter].
  /// * [clipper]: If non-null, determines which clip to use.
  /// * [liquid]: If non-null, renders liquid glass with these settings, for
  ///   example [LiquidGlass.regular]. Defaults to null, which renders plain glass.
  Widget asGlass({
    bool enabled = true,
    double? blurX,
    double? blurY,
    Color? tintColor,
    bool? frosted,
    BorderRadius clipBorderRadius = BorderRadius.zero,
    Clip? clipBehavior,
    @Deprecated('Use clipBehavior instead. Will be removed in 3.0.0.')
    Clip? clipBehaviour,
    TileMode tileMode = TileMode.clamp,
    CustomClipper<RRect>? clipper,
    LiquidGlass? liquid,
  }) {
    final tint = tintColor ?? liquid?.tintColor ?? Colors.white;
    // Plain glass keeps its exact 10% → 8% gradient.
    final tintStart = liquid?.tintStrength ?? 0.1;
    final tintEnd = liquid == null ? 0.08 : liquid.tintStrength;
    final blur = ImageFilter.blur(
      sigmaX: blurX ?? liquid?.blur ?? 10.0,
      sigmaY: blurY ?? liquid?.blur ?? 10.0,
      tileMode: tileMode,
    );
    return !enabled
        ? this
        : _GlassBackdrop(
            blur: blur,
            liquid: liquid,
            clipper: clipper,
            clipBehavior: clipBehavior ?? clipBehaviour ?? Clip.antiAlias,
            borderRadius: clipBorderRadius,
            child: Container(
              decoration: BoxDecoration(
                gradient: (tint != Colors.transparent)
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tint.withValues(alpha: tintStart),
                          tint.withValues(alpha: tintEnd),
                        ],
                      )
                    : null,
                image: (frosted ?? liquid == null)
                    ? DecorationImage(
                        image: AssetImage('images/noise.png', package: 'glass'),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: this,
            ),
          );
  }
}

/// Clips to the glass shape and blurs the backdrop. When [liquid] is set and
/// shaders are available, the blur and the refraction are one backdrop filter
/// (`compose(outer: refraction shader, inner: blur)`), so liquid glass takes
/// two passes:
///
/// 1. Clip, blur, refract (inward only, so the clip is the glass shape) and
///    tint (the child).
/// 2. The rim, painted last so the blur does not soften it.
class _GlassBackdrop extends StatefulWidget {
  const _GlassBackdrop({
    required this.blur,
    required this.liquid,
    required this.clipper,
    required this.clipBehavior,
    required this.borderRadius,
    required this.child,
  });

  final ImageFilter blur;
  final LiquidGlass? liquid;
  final CustomClipper<RRect>? clipper;
  final Clip clipBehavior;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<_GlassBackdrop> {
  static Future<List<FragmentProgram>>? _programs;
  FragmentShader? _refraction;
  FragmentShader? _rim;
  ImageFilter? _filter;
  ImageFilter? _filterBlur;

  @override
  void initState() {
    super.initState();
    _maybeLoadShaders();
  }

  @override
  void didUpdateWidget(_GlassBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoadShaders();
  }

  void _maybeLoadShaders() {
    if (widget.liquid == null ||
        _refraction != null ||
        !ImageFilter.isShaderFilterSupported) {
      return;
    }
    _programs ??= Future.wait([
      FragmentProgram.fromAsset('packages/glass/shaders/liquid_glass.frag'),
      FragmentProgram.fromAsset('packages/glass/shaders/liquid_rim.frag'),
    ]);
    _programs!.then((programs) {
      if (!mounted) return;
      setState(() {
        _refraction = programs[0].fragmentShader();
        _rim = programs[1].fragmentShader();
      });
    }, onError: (Object _) {}); // Keep the plain blur if loading fails.
  }

  @override
  void dispose() {
    _refraction?.dispose();
    _rim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liquid = widget.liquid;
    final refraction = _refraction;
    final rim = _rim;
    final live = liquid != null && refraction != null && rim != null;
    if (live && !identical(_filterBlur, widget.blur)) {
      // The uniforms are set at paint time, the filter object stays the same.
      _filterBlur = widget.blur;
      _filter = ImageFilter.compose(
        outer: ImageFilter.shader(refraction),
        inner: widget.blur,
      );
    }
    // Clip to the shape, blur (and refract) what is behind, then the tint.
    final glass = ClipRRect(
      clipper: widget.clipper,
      clipBehavior: widget.clipBehavior,
      borderRadius: widget.borderRadius,
      child: BackdropFilter(
        filter: live ? _filter! : widget.blur,
        child: widget.child,
      ),
    );
    if (!live) return glass;
    return _LiquidGlassLayers(
      refraction: refraction,
      rim: rim,
      liquid: liquid,
      radius: widget.borderRadius.topLeft.x,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: glass,
    );
  }
}

class _LiquidGlassLayers extends SingleChildRenderObjectWidget {
  const _LiquidGlassLayers({
    required this.refraction,
    required this.rim,
    required this.liquid,
    required this.radius,
    required this.devicePixelRatio,
    super.child,
  });

  final FragmentShader refraction;
  final FragmentShader rim;
  final LiquidGlass liquid;
  final double radius;
  final double devicePixelRatio;

  @override
  _RenderLiquidGlassLayers createRenderObject(BuildContext context) =>
      _RenderLiquidGlassLayers(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLiquidGlassLayers renderObject,
  ) {
    renderObject.config = this;
  }
}

/// Lays out like its child. Sets the refraction uniforms before the child
/// paints (the child holds the backdrop filter) and paints the rim after it.
/// Hit testing is unchanged.
class _RenderLiquidGlassLayers extends RenderProxyBox {
  _RenderLiquidGlassLayers(this._config);

  _LiquidGlassLayers _config;
  set config(_LiquidGlassLayers value) {
    _config = value;
    markNeedsPaint();
  }

  /// Paints [shadow] around the glass shape, but not under it.
  void _paintShadow(Canvas canvas, Offset offset, BoxShadow shadow) {
    final rrect = RRect.fromRectAndRadius(
      offset & size,
      Radius.circular(math.min(_config.radius, size.shortestSide / 2)),
    );
    final reach = shadow.blurRadius * 1.5 + shadow.offset.distance;
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rrect.outerRect.inflate(reach))
      ..addRRect(rrect);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        rrect.shift(shadow.offset),
        shadow.toPaint(),
      )
      ..restore();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = _config;
    final dpr = c.devicePixelRatio;
    // Band width W and displacement scale A (A = 3 W), in logical pixels.
    final width =
        c.liquid.edgeWidth ?? math.min(20.0, 0.69 * size.shortestSide / 2);
    final amount = 3 * width * c.liquid.refraction;

    // Spike: the position goes stale if an ancestor moves this box without
    // repainting it (for example while scrolling).
    final origin = localToGlobal(Offset.zero) * dpr;
    c.refraction
      ..setFloat(2, origin.dx)
      ..setFloat(3, origin.dy)
      ..setFloat(4, size.width * dpr)
      ..setFloat(5, size.height * dpr)
      ..setFloat(6, c.radius * dpr)
      ..setFloat(7, width * dpr)
      ..setFloat(8, amount * dpr)
      ..setFloat(9, c.liquid.lift)
      ..setFloat(10, c.liquid.midtoneLift);

    final shadow = c.liquid.shadow;
    if (shadow != null) _paintShadow(context.canvas, offset, shadow);

    // Clip, blur, refract and tint (the child).
    super.paint(context, offset);

    // The rim, crisp on top of everything.
    // A paint shader works in canvas (logical) coordinates, unlike the
    // backdrop shader above, which works in physical pixels of the target.
    c.rim
      ..setFloat(0, offset.dx)
      ..setFloat(1, offset.dy)
      ..setFloat(2, size.width)
      ..setFloat(3, size.height)
      ..setFloat(4, c.radius)
      ..setFloat(5, c.liquid.highlight)
      ..setFloat(6, dpr);
    context.canvas.drawRect(
      offset & size,
      Paint()..shader = c.rim,
    );
  }
}
