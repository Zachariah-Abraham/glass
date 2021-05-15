import 'package:flutter/material.dart';
import 'dart:ui';

extension GlassWidget on Widget {
  ClipRRect asGlass({
    /// The border radius of the rounded corners.
    ///
    /// Values are clamped so that horizontal and vertical radii sums do not exceed width/height.
    /// This value is ignored if [clipper] is non-null.
    BorderRadius? clipBorderRadius = BorderRadius.zero,

    /// Amount of blur in the direction of the X axis.
    double blurX = 4.0,

    /// Amount of blur in the direction of the Y axis.
    double blurY = 4.0,

    /// Defines what happens at the edge of a gradient or the sampling of a source image in an [ImageFilter].
    ///
    /// A gradient is defined along a finite inner area. In the case of a linear gradient, it's between the parallel lines that are orthogonal to the line drawn between two points. In the case of radial gradients, it's the disc that covers the circle centered on a particular point up to a given radius.
    /// An image filter reads source samples from a source image and performs operations on those samples to produce a result image. An image defines color samples only for pixels within the bounds of the image but some filter operations, such as a blur filter, read samples over a wide area to compute the output for a given pixel. Such a filter would need to combine samples from inside the image with hypothetical color values from outside the image.
    /// This enum is used to define how the gradient or image filter should treat the regions outside that defined inner area.
    /// See also:
    /// [painting.Gradient], the superclass for [LinearGradient] and [RadialGradient], as used by [BoxDecoration] et al, which works in relative coordinates and can create a [Shader] representing the gradient for a particular [Rect] on demand.
    /// [dart:ui.Gradient], the low-level class used when dealing with the [Paint.shader] property directly, with its [Gradient.linear] and [Gradient.radial] constructors.
    /// [dart:ui.ImageFilter.blur], an ImageFilter that may sometimes need to read samples from outside an image to combine with the pixels near the edge of the image.
    TileMode tileMode = TileMode.clamp,

    /// If non-null, determines which clip to use.
    CustomClipper<RRect>? clipper,

    /// Defaults to [Clip.antiAlias].
    Clip clipBehaviour = Clip.antiAlias,
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
