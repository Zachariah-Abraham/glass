#version 460 core
#include <flutter/runtime_effect.glsl>

// Rim highlight of liquid glass, drawn as an ordinary paint on top of the
// blurred glass so it stays crisp. Alpha is premultiplied.

// Unlike a backdrop filter, a paint shader's FlutterFragCoord() is in the
// canvas coordinates of the draw call (logical pixels, the same space as the
// rect that is drawn), so the rect and radius here are logical. Measured on
// macOS (Impeller/Metal).
uniform vec4 uRect;         // floats 0-3: glass rect left, top, width, height (logical px)
uniform float uRadius;      // float 4: corner radius in logical px
uniform float uHighlight;   // float 5: rim highlight intensity 0..1
uniform float uScale;       // float 6: physical pixels per logical pixel

out vec4 fragColor;

// Signed distance to a rounded rect (negative inside). Also returns the outward
// gradient in `grad`. A future version can replace this with a smooth-min union
// of several rects as long as it keeps returning (distance, gradient).
float shapeSdf(vec2 p, out vec2 grad) {
  vec2 half_ = uRect.zw * 0.5;
  float r = clamp(uRadius, 0.0, min(half_.x, half_.y));
  vec2 c = p - (uRect.xy + half_);
  vec2 q = abs(c) - (half_ - vec2(r));
  vec2 qm = max(q, 0.0);
  float d = length(qm) + min(max(q.x, q.y), 0.0) - r;
  // Analytic gradient (pointing outward).
  vec2 g = (qm.x > 0.0 || qm.y > 0.0)
      ? qm / max(length(qm), 1e-5)
      : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
  grad = g * sign(c + vec2(1e-5));
  return d;
}

void main() {
  vec2 grad;
  // Work in physical pixels from here on so the rim keeps a ~2px width.
  float d = shapeSdf(FlutterFragCoord().xy, grad) * uScale;
  float cover = 1.0 - smoothstep(-0.5, 0.5, d);
  float depth = max(-d, 0.0);

  // Measured on Apple's glass: a pure white hairline whose coverage is about
  // 0.55, 0.41, 0.26 on the first three physical pixels inside the edge, with
  // the same strength all around the shape (no light direction).
  float line = max(0.55 - 0.126 * depth, 0.0) * (1.0 - smoothstep(2.8, 3.4, depth));
  float a = clamp(line * uHighlight, 0.0, 1.0) * cover;
  fragColor = vec4(vec3(a), a);
}
