import 'package:flutter/material.dart';
import 'dart:ui';

extension GlassWidget on Widget {
  /// .asGlass(): Converts the calling widget into a glass widget.
  ///
  /// Parameters:
  /// * [blurX]: Amount of blur in the direction of the X axis.
  /// * [blurY]: Amount of blur in the direction of the Y axis.
  /// * [clipBorderRadius]: The border radius of the rounded corners.
  ///   Values are clamped so that horizontal and vertical radii sums do not exceed width/height.
  ///   This value is ignored if [clipper] is non-null.
  /// * [clipBehaviour]: Defaults to [Clip.antiAlias].
  /// * [tileMode]: Defines what happens at the edge of a gradient or the sampling of a source image in an [ImageFilter].
  /// * [clipper]: If non-null, determines which clip to use.
  ClipRRect asGlass({
    double blurX = 4.0,
    double blurY = 4.0,
    BorderRadius? clipBorderRadius = BorderRadius.zero,
    Clip clipBehaviour = Clip.antiAlias,
    TileMode tileMode = TileMode.clamp,
    CustomClipper<RRect>? clipper,
  }) {
    return ClipRRect(
      clipper: clipper,
      clipBehavior: clipBehaviour,
      borderRadius: clipBorderRadius,
      child: BackdropFilter(
        filter: new ImageFilter.blur(
          sigmaX: blurX,
          sigmaY: blurY,
          tileMode: tileMode,
        ),
        child: this,
      ),
    );
  }
}
