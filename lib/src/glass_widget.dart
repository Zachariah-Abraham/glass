import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
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
/// The bending follows the glass's clip shape: the rounded rectangle given by
/// `clipBorderRadius` (each corner can have its own, also elliptical, radius)
/// or by `clipper`.
class LiquidGlass {
  /// Creates liquid glass settings.
  ///
  /// * [blur]: Blur sigma along both axes, defaults to 3.0 (1.6 for [clear]).
  /// * [tintColor]: Tint color of the glass, defaults to [Colors.white].
  /// * [tintStrength]: Opacity of the tint from 0 to 1, defaults to 0.1.
  /// * [saturation]: Saturation of the blurred backdrop before the tint, 1.0
  ///   (the default) leaves it unchanged, 0 makes it grey and values above 1
  ///   make colors more vivid, as Apple's `Glass.regular` does (about 2.3).
  /// * [refraction]: How strongly the edges bend the backdrop, 0 for none.
  ///   1.0, the default, matches Apple's native glass.
  /// * [edgeWidth]: Width of the refracting edge band in logical pixels.
  ///   Defaults to null, which uses `min(20, 0.69 * R)` where R is half the
  ///   shorter side, as measured on Apple's glass.
  /// * [lift]: Brightness added to the blurred backdrop before the tint, from
  ///   0 to 1 (0.075 is about 19 of 255), defaults to 0.
  /// * [midtoneLift]: Brightens the mid-tones of the blurred backdrop before
  ///   the tint (`x += midtoneLift * x * (1 - x)`), which makes the tinted
  ///   result slightly concave like Apple's glass. Defaults to 0 (linear).
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
    this.saturation = 1.0,
    this.refraction = 1.0,
    this.edgeWidth,
    this.lift = 0.0,
    this.midtoneLift = 0.0,
    this.highlight = 1.0,
    this.shadow,
  });

  /// Loads the liquid glass shader ahead of time.
  ///
  /// The shader loads asynchronously the first time a liquid glass is built,
  /// and until it has loaded, liquid glass draws a plain blur and tint. To
  /// show liquid glass from the first frame, call this before the first liquid
  /// glass is shown, for example in `main()`:
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await LiquidGlass.precache();
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// The shader is loaded only once, so later calls are cheap. Completes right
  /// away where shader filters aren't supported (see
  /// [ImageFilter.isShaderFilterSupported]), and never throws: if loading
  /// fails, liquid glass keeps the plain blur.
  static Future<void> precache() async {
    if (!ImageFilter.isShaderFilterSupported) return;
    try {
      await _GlassBackdropState._loadProgram();
    } catch (_) {
      // Keep the plain blur, as a liquid glass does when loading fails.
    }
  }

  /// Frosted, mostly opaque glass with a light tint, like Apple's
  /// `Glass.regular`. Use it where legibility of content on the glass matters.
  static const regular = LiquidGlass(
    blur: 7.0,
    tintColor: Color(0xFFF7F7F7),
    tintStrength: 0.731,
    saturation: 2.32,
    midtoneLift: 0.242,
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

  /// Saturation of the blurred backdrop before the tint, 1.0 for unchanged.
  ///
  /// Only applies where the backdrop bends (with Impeller), like [refraction].
  final double saturation;

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
    double? saturation,
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
      saturation: saturation ?? this.saturation,
      refraction: refraction ?? this.refraction,
      edgeWidth: edgeWidth ?? this.edgeWidth,
      lift: lift ?? this.lift,
      midtoneLift: midtoneLift ?? this.midtoneLift,
      highlight: highlight ?? this.highlight,
      shadow: shadow ?? this.shadow,
    );
  }
}

/// Adds [asGlass] to every widget, so any widget can become a frosted or
/// liquid glass version of itself.
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
  /// * [grouped]: Whether this glass shares its backdrop with the other grouped
  ///   glass (and [BackdropFilter.grouped] widgets) under the nearest
  ///   [BackdropGroup]. On Impeller this makes many glass widgets on screen,
  ///   for example the cards of a list, much cheaper to draw. Each grouped
  ///   glass blurs the backdrop as it was before the group's first one was
  ///   drawn, so grouped glass that overlaps other glass doesn't show it
  ///   through. Defaults to false. Has no effect without a [BackdropGroup]
  ///   ancestor.
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
    bool grouped = false,
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
          grouped: grouped,
          clipper: clipper,
          clipBehavior: clipBehavior ?? clipBehaviour ?? Clip.antiAlias,
          borderRadius: clipBorderRadius,
          tint: tint,
          gradient:
              (tint != Colors.transparent)
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint.withValues(alpha: tintStart),
                      tint.withValues(alpha: tintEnd),
                    ],
                  )
                  : null,
          image:
              (frosted ?? liquid == null)
                  ? DecorationImage(
                    image: AssetImage('images/noise.png', package: 'glass'),
                    fit: BoxFit.cover,
                  )
                  : null,
          child: this,
        );
  }
}

/// Clips to the glass shape and blurs the backdrop. When [liquid] is set and
/// shaders are available, a blur backdrop filter is followed by a refraction
/// shader backdrop filter, which reads the blurred backdrop. The shader refracts
/// (inward only, so the clip is the glass shape), saturates, tints and draws
/// the rim, all after the blur so the rim stays crisp. It does the tint itself
/// because saturation can push colors below 0 before the tint and the tint
/// must see that, so the tint [gradient] is only painted when the shader isn't
/// used. The rim is in the shader too because it depends on the backdrop.
class _GlassBackdrop extends StatefulWidget {
  const _GlassBackdrop({
    required this.blur,
    required this.liquid,
    required this.grouped,
    required this.clipper,
    required this.clipBehavior,
    required this.borderRadius,
    required this.tint,
    required this.gradient,
    required this.image,
    required this.child,
  });

  final ImageFilter blur;
  final LiquidGlass? liquid;
  final bool grouped;
  final CustomClipper<RRect>? clipper;
  final Clip clipBehavior;
  final BorderRadius borderRadius;

  /// The tint color, used by the shader.
  final Color tint;

  /// The tint as painted on top of the blur when the shader isn't used.
  final Gradient? gradient;

  /// The frost (noise) texture, or null.
  final DecorationImage? image;
  final Widget child;

  @override
  State<_GlassBackdrop> createState() => _GlassBackdropState();
}

class _GlassBackdropState extends State<_GlassBackdrop> {
  static Future<FragmentProgram>? _program;
  static FragmentProgram? _loadedProgram;
  FragmentShader? _refraction;

  /// Starts loading the shader the first time it is called, and returns the
  /// shared load.
  static Future<FragmentProgram> _loadProgram() {
    return _program ??= FragmentProgram.fromAsset(
      'packages/glass/shaders/liquid_glass.frag',
    ).then((program) => _loadedProgram = program);
  }

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
    // Once loaded, later glass widgets use the shader from their first frame.
    final loaded = _loadedProgram;
    if (loaded != null) {
      _refraction = loaded.fragmentShader();
      return;
    }
    _loadProgram().then((program) {
      if (!mounted || _refraction != null) return;
      setState(() => _refraction = program.fragmentShader());
    }, onError: (Object _) {}); // Keep the plain blur if loading fails.
  }

  @override
  void dispose() {
    _refraction?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liquid = widget.liquid;
    final refraction = _refraction;
    final live = liquid != null && refraction != null;
    final shape = _GlassShape(widget.clipper, widget.borderRadius);
    final content = Container(
      decoration: BoxDecoration(
        gradient: live ? null : widget.gradient,
        image: widget.image,
      ),
      child: widget.child,
    );
    // Clip to the shape, blur (and refract) what is behind, then the tint.
    final glass = ClipRRect(
      clipper: widget.clipper,
      clipBehavior: widget.clipBehavior,
      borderRadius: widget.borderRadius,
      child:
          live
              ? _LiquidBackdrop(
                blur: widget.blur,
                refraction: refraction,
                liquid: liquid,
                backdropKey:
                    widget.grouped
                        ? BackdropGroup.of(context)?.backdropKey
                        : null,
                tint:
                    widget.gradient == null ? Colors.transparent : widget.tint,
                shape: shape,
                devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                child: content,
              )
              : widget.grouped
              ? BackdropFilter.grouped(filter: widget.blur, child: content)
              : BackdropFilter(filter: widget.blur, child: content),
    );
    if (!live) return glass;
    return _LiquidGlassLayers(liquid: liquid, shape: shape, child: glass);
  }
}

/// The glass's clip shape, as [ClipRRect] computes it from the same clipper
/// and border radius.
class _GlassShape {
  const _GlassShape(this.clipper, this.borderRadius);

  final CustomClipper<RRect>? clipper;
  final BorderRadius borderRadius;

  /// The shape for a glass of [size], in its local coordinates. Radii that
  /// don't fit are scaled down, as the clip does.
  RRect rrect(Size size) =>
      (clipper?.getClip(size) ?? borderRadius.toRRect(Offset.zero & size))
          .scaleRadii();
}

class _LiquidGlassLayers extends SingleChildRenderObjectWidget {
  const _LiquidGlassLayers({
    required this.liquid,
    required this.shape,
    super.child,
  });

  final LiquidGlass liquid;
  final _GlassShape shape;

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

/// Lays out like its child and paints the shadow before the child (the
/// child holds the backdrop filter). Hit testing is unchanged.
class _RenderLiquidGlassLayers extends RenderProxyBox {
  _RenderLiquidGlassLayers(this._config);

  _LiquidGlassLayers _config;
  set config(_LiquidGlassLayers value) {
    _config = value;
    markNeedsPaint();
  }

  /// Paints [shadow] around the glass shape, but not under it.
  void _paintShadow(Canvas canvas, Offset offset, BoxShadow shadow) {
    final rrect = _config.shape.rrect(size).shift(offset);
    final reach = shadow.blurRadius * 1.5 + shadow.offset.distance;
    final outside =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rrect.outerRect.inflate(reach))
          ..addRRect(rrect);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(rrect.shift(shadow.offset), shadow.toPaint())
      ..restore();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final shadow = _config.liquid.shadow;
    if (shadow != null) _paintShadow(context.canvas, offset, shadow);

    // Clip, blur, refract, saturate, tint and rim, then the child.
    super.paint(context, offset);
  }
}

/// A backdrop filter that blurs, then runs the liquid glass shader.
class _LiquidBackdrop extends SingleChildRenderObjectWidget {
  const _LiquidBackdrop({
    required this.blur,
    required this.refraction,
    required this.liquid,
    required this.backdropKey,
    required this.tint,
    required this.shape,
    required this.devicePixelRatio,
    super.child,
  });

  final ImageFilter blur;
  final FragmentShader refraction;
  final LiquidGlass liquid;

  /// The shared backdrop the blur reads, or null for its own.
  final BackdropKey? backdropKey;
  final Color tint;
  final _GlassShape shape;
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

/// Pushes a [_LiquidBackdropLayer] and computes the shader uniforms for it,
/// including the transform from the glass to the screen.
class _RenderLiquidBackdrop extends RenderProxyBox {
  _RenderLiquidBackdrop(this._config);

  _LiquidBackdrop _config;
  set config(_LiquidBackdrop value) {
    _config = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  _LiquidBackdropLayer? get layer => super.layer as _LiquidBackdropLayer?;

  /// The shader uniforms from float 2 on (floats 0-1 are set by the engine).
  List<double> _uniforms() {
    final c = _config;
    final dpr = c.devicePixelRatio;
    // Local logical pixels to screen physical pixels, restricted to the z = 0
    // plane: a 3x3 projective matrix (rows x, y, w of the 4x4 transform,
    // columns x, y, translation). This handles scale, rotation, skew and
    // perspective, for example from page transitions or a Transform.
    final m = attached && hasSize ? getTransformTo(null) : Matrix4.zero();
    final fwd = [
      for (final row in const [0, 1, 3])
        for (final col in const [0, 1, 3])
          m.entry(row, col) * (row == 3 ? 1 : dpr),
    ];
    final inv = _invert3(fwd);
    final shape = c.shape.rrect(hasSize ? size : Size.zero);
    // Band width W and displacement scale A (A = 3 W), in local logical px.
    final width =
        c.liquid.edgeWidth ??
        math.min(20.0, 0.69 * shape.outerRect.shortestSide / 2);
    final amount = 3 * width * c.liquid.refraction;
    return [
      shape.left, // 2-5: the shape's rect
      shape.top,
      shape.right,
      shape.bottom,
      shape.tlRadiusX, // 6-9: corner radii along x
      shape.trRadiusX,
      shape.brRadiusX,
      shape.blRadiusX,
      shape.tlRadiusY, // 10-13: corner radii along y
      shape.trRadiusY,
      shape.brRadiusY,
      shape.blRadiusY,
      width, // 14
      amount, // 15
      ...inv, // 16-24: screen physical px to local, rows
      ...fwd, // 25-33: local to screen physical px, rows
      c.liquid.lift, // 34
      c.liquid.midtoneLift, // 35
      c.tint.r, // 36-38
      c.tint.g,
      c.tint.b,
      c.tint == Colors.transparent ? 0 : c.liquid.tintStrength, // 39
      c.liquid.saturation, // 40
      c.liquid.highlight, // 41
    ];
  }

  /// The inverse of a row-major 3x3 matrix, or all zeros if it is singular
  /// (for example glass turned edge-on, which shows nothing anyway).
  static List<double> _invert3(List<double> a) {
    final [a0, a1, a2, a3, a4, a5, a6, a7, a8] = a;
    final c0 = a4 * a8 - a5 * a7;
    final c1 = a5 * a6 - a3 * a8;
    final c2 = a3 * a7 - a4 * a6;
    final det = a0 * c0 + a1 * c1 + a2 * c2;
    if (det == 0 || !det.isFinite) return List.filled(9, 0);
    final k = 1 / det;
    return [
      c0 * k,
      (a2 * a7 - a1 * a8) * k,
      (a1 * a5 - a2 * a4) * k,
      c1 * k,
      (a0 * a8 - a2 * a6) * k,
      (a2 * a3 - a0 * a5) * k,
      c2 * k,
      (a1 * a6 - a0 * a7) * k,
      (a0 * a4 - a1 * a3) * k,
    ];
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    final backdrop = layer ??= _LiquidBackdropLayer();
    backdrop
      ..blur = _config.blur
      ..blurBackdropKey = _config.backdropKey
      ..shader = _config.refraction
      ..uniforms = _uniforms;
    context.pushLayer(backdrop, super.paint, offset);
  }
}

/// A [BackdropFilterLayer] that is added to every scene, even when nothing
/// was repainted, and builds its filter right before it is pushed.
///
/// The shader needs the glass rect in physical pixels of the whole screen. An
/// ancestor can move the glass without repainting it (for example a scroll
/// view moving a repaint boundary), and a retained layer would keep the old
/// rect. Always adding this layer also adds its ancestors, but its siblings
/// and children stay retained.
///
/// The engine copies a shader's uniforms when a filter object is first used,
/// so changing them later has no effect on that filter. This layer therefore
/// makes a new filter whenever the uniforms changed, and reuses the old one
/// otherwise.
///
/// The blur is its own backdrop filter, pushed just before the shader's.
/// Composing the two into one filter makes Impeller blur far beyond the
/// glass's clip, which is slow for a small blur (one that isn't downsampled):
/// a list of a dozen [LiquidGlass.clear] cards took about 20 ms per frame on
/// an Adreno phone composed, against about 7 ms separate.
///
/// With [blurBackdropKey], the blur reads the shared backdrop of a
/// [BackdropGroup] and the shader still reads the blurred result. The shader
/// can't share it, since the shared backdrop isn't blurred.
class _LiquidBackdropLayer extends BackdropFilterLayer {
  ImageFilter? blur;
  BackdropKey? blurBackdropKey;
  FragmentShader? shader;
  List<double> Function()? uniforms;

  ImageFilter? _filter;
  FragmentShader? _filterShader;
  List<double>? _filterUniforms;

  /// Pushes the blur. It is not in the layer tree: [addToScene] adds it, so
  /// it has no children and ends before the shader's filter starts.
  final _blurLayer = BackdropFilterLayer();

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  ImageFilter? get filter => _filter;

  @override
  void addToScene(SceneBuilder builder) {
    final shader = this.shader!, values = uniforms!();
    if (_filter == null ||
        !identical(shader, _filterShader) ||
        !listEquals(values, _filterUniforms)) {
      for (var i = 0; i < values.length; i++) {
        shader.setFloat(i + 2, values[i]);
      }
      _filter = ImageFilter.shader(shader);
      _filterShader = shader;
      _filterUniforms = values;
    }
    _blurLayer
      ..filter = blur
      ..backdropKey = blurBackdropKey
      ..addToScene(builder);
    super.addToScene(builder);
  }

  @override
  void dispose() {
    _blurLayer.dispose();
    super.dispose();
  }
}
