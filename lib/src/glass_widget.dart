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
  /// * [blur]: Blur sigma along both axes, defaults to 2.0.
  /// * [tintColor]: Tint color of the glass, defaults to [Colors.black].
  /// * [tintStrength]: Opacity of the tint from 0 to 1, defaults to 0.15.
  /// * [refraction]: How strongly the edges bend the backdrop, 0 for none,
  ///   defaults to 1.0.
  /// * [edgeWidth]: Width of the curved edge in logical pixels. Defaults to
  ///   null, which uses half the shorter side, so the whole shape is curved.
  /// * [highlight]: Intensity of the rim from 0 to 1, defaults to 0.6.
  const LiquidGlass({
    this.blur = 2.0,
    this.tintColor = Colors.black,
    this.tintStrength = 0.15,
    this.refraction = 1.0,
    this.edgeWidth,
    this.highlight = 0.6,
  });

  /// Frosted, mostly opaque glass with a light tint, like Apple's
  /// `Glass.regular`. Use it where legibility of content on the glass matters.
  static const regular = LiquidGlass(
    blur: 8.0,
    tintColor: Colors.white,
    tintStrength: 0.45,
  );

  /// Highly transparent glass with a slight dark tint, like Apple's
  /// `Glass.clear`. Use it over rich media.
  static const clear = LiquidGlass();

  /// Blur sigma along both axes.
  final double blur;

  /// Tint color of the glass.
  final Color tintColor;

  /// Opacity of the tint from 0 to 1.
  final double tintStrength;

  /// Strength of the edge refraction.
  final double refraction;

  /// Width of the curved edge in logical pixels, or null for half the
  /// shorter side.
  final double? edgeWidth;

  /// Intensity of the rim.
  final double highlight;

  /// Returns a copy with the given fields replaced.
  LiquidGlass copyWith({
    double? blur,
    Color? tintColor,
    double? tintStrength,
    double? refraction,
    double? edgeWidth,
    double? highlight,
  }) {
    return LiquidGlass(
      blur: blur ?? this.blur,
      tintColor: tintColor ?? this.tintColor,
      tintStrength: tintStrength ?? this.tintStrength,
      refraction: refraction ?? this.refraction,
      edgeWidth: edgeWidth ?? this.edgeWidth,
      highlight: highlight ?? this.highlight,
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
    final tintEnd = liquid == null ? 0.08 : liquid.tintStrength * 0.8;
    final blur = ImageFilter.blur(
      sigmaX: blurX ?? liquid?.blur ?? 10.0,
      sigmaY: blurY ?? liquid?.blur ?? 10.0,
      tileMode: tileMode,
    );
    return !enabled
        ? this
        : ClipRRect(
            clipper: clipper,
            clipBehavior: clipBehavior ?? clipBehaviour ?? Clip.antiAlias,
            borderRadius: clipBorderRadius,
            child: _GlassBackdrop(
              blur: blur,
              liquid: liquid,
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
                          image:
                              AssetImage('images/noise.png', package: 'glass'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: this,
              ),
            ),
          );
  }
}

/// Blurs the backdrop, and bends it with the liquid glass shader when
/// [liquid] is set and shaders are available.
class _GlassBackdrop extends StatefulWidget {
  const _GlassBackdrop({
    required this.blur,
    required this.liquid,
    required this.borderRadius,
    required this.child,
  });

  final ImageFilter blur;
  final LiquidGlass? liquid;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<_GlassBackdrop> {
  static Future<FragmentProgram>? _program;
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _maybeLoadShader();
  }

  @override
  void didUpdateWidget(_GlassBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoadShader();
  }

  void _maybeLoadShader() {
    if (widget.liquid == null ||
        _shader != null ||
        !ImageFilter.isShaderFilterSupported) {
      return;
    }
    _program ??= FragmentProgram.fromAsset(
      'packages/glass/shaders/liquid_glass.frag',
    );
    _program!.then((program) {
      if (mounted) setState(() => _shader = program.fragmentShader());
    }, onError: (Object _) {}); // Keep the plain blur if loading fails.
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liquid = widget.liquid;
    final shader = _shader;
    if (liquid == null || shader == null) {
      return BackdropFilter(filter: widget.blur, child: widget.child);
    }
    return _LiquidBackdrop(
      shader: shader,
      blur: widget.blur,
      liquid: liquid,
      radius: widget.borderRadius.topLeft.x,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      child: widget.child,
    );
  }
}

class _LiquidBackdrop extends SingleChildRenderObjectWidget {
  const _LiquidBackdrop({
    required this.shader,
    required this.blur,
    required this.liquid,
    required this.radius,
    required this.devicePixelRatio,
    super.child,
  });

  final FragmentShader shader;
  final ImageFilter blur;
  final LiquidGlass liquid;
  final double radius;
  final double devicePixelRatio;

  @override
  _RenderLiquidBackdrop createRenderObject(BuildContext context) =>
      _RenderLiquidBackdrop(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLiquidBackdrop renderObject,
  ) {
    renderObject.config = this;
  }
}

class _RenderLiquidBackdrop extends RenderProxyBox {
  _RenderLiquidBackdrop(this._config);

  _LiquidBackdrop _config;
  set config(_LiquidBackdrop value) {
    _config = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = _config;
    final dpr = c.devicePixelRatio;
    // Spike: assumes the shader sees the whole screen in physical pixels.
    // The position goes stale if an ancestor moves this box without
    // repainting it (for example while scrolling).
    final origin = localToGlobal(Offset.zero) * dpr;
    c.shader
      ..setFloat(2, origin.dx)
      ..setFloat(3, origin.dy)
      ..setFloat(4, size.width * dpr)
      ..setFloat(5, size.height * dpr)
      ..setFloat(6, c.radius * dpr)
      ..setFloat(7, (c.liquid.edgeWidth ?? size.shortestSide / 2) * dpr)
      ..setFloat(8, c.liquid.refraction)
      ..setFloat(9, c.liquid.highlight);
    final layer = (this.layer as BackdropFilterLayer?) ?? BackdropFilterLayer();
    layer.filter = ImageFilter.compose(
      outer: ImageFilter.shader(c.shader),
      inner: c.blur,
    );
    this.layer = layer;
    context.pushLayer(layer, super.paint, offset);
  }
}
