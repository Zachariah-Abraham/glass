import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';

/// Settings for the liquid glass look: the backdrop bends near the edges of
/// the glass, with a light rim highlight.
///
/// Pass it to [GlassWidget.asGlass] as `liquid`. Needs the Impeller renderer;
/// elsewhere (for example on web) the glass falls back to the plain blur.
///
/// Spike: only uniform corner radii are supported.
class LiquidGlass {
  /// Creates liquid glass settings.
  ///
  /// * [thickness]: Width of the curved edge band where light bends, in
  ///   logical pixels, defaults to 20.0.
  /// * [refraction]: How strongly the edge bends the backdrop, 0 for none,
  ///   defaults to 1.0.
  /// * [highlight]: Intensity of the rim highlight from 0 to 1, defaults to 0.6.
  const LiquidGlass({
    this.thickness = 20.0,
    this.refraction = 1.0,
    this.highlight = 0.6,
  });

  /// Width of the curved edge band in logical pixels.
  final double thickness;

  /// Strength of the edge refraction.
  final double refraction;

  /// Intensity of the rim highlight.
  final double highlight;
}

extension GlassWidget<T extends Widget> on T {
  /// .asGlass(): Converts the calling widget into a glass widget.
  ///
  /// Parameters:
  /// * [enabled]: Enable or disable all effects, defaults to true.
  /// * [blurX]: Amount of blur in the direction of the X axis, defaults to 10.0.
  /// * [blurY]: Amount of blur in the direction of the Y axis, defaults to 10.0.
  /// * [tintColor]: Tint color for the glass (defaults to Colors.white).
  /// * [frosted]: Whether this glass should be frosted or not, defaults to true.
  /// * [clipBorderRadius]: The border radius of the rounded corners.
  ///   Values are clamped so that horizontal and vertical radii sums do not exceed width/height.
  ///   This value is ignored if clipper is non-null.
  /// * [clipBehavior]: How the glass is clipped, defaults to [Clip.antiAlias].
  /// * [clipBehaviour]: Deprecated misspelling of [clipBehavior]. Ignored if [clipBehavior] is set.
  /// * [tileMode]: Defines what happens at the edge of a gradient or the sampling of a source image in an [ImageFilter].
  /// * [clipper]: If non-null, determines which clip to use.
  /// * [liquid]: If non-null, adds the liquid glass look (see [LiquidGlass]).
  ///   Defaults to null, which renders plain glass.
  Widget asGlass({
    bool enabled = true,
    double blurX = 10.0,
    double blurY = 10.0,
    Color tintColor = Colors.white,
    bool frosted = true,
    BorderRadius clipBorderRadius = BorderRadius.zero,
    Clip? clipBehavior,
    @Deprecated('Use clipBehavior instead. Will be removed in 3.0.0.')
    Clip? clipBehaviour,
    TileMode tileMode = TileMode.clamp,
    CustomClipper<RRect>? clipper,
    LiquidGlass? liquid,
  }) {
    final blur = ImageFilter.blur(
      sigmaX: blurX,
      sigmaY: blurY,
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
                  gradient: (tintColor != Colors.transparent)
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tintColor.withValues(alpha: 0.1),
                            tintColor.withValues(alpha: 0.08),
                          ],
                        )
                      : null,
                  image: frosted
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
      ..setFloat(7, c.liquid.thickness * dpr)
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
