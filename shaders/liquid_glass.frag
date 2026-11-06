#version 460 core
#include <flutter/runtime_effect.glsl>

// Refraction of liquid glass, used as the outer part of a backdrop filter whose
// inner part is the blur (so this shader reads the already blurred backdrop).
// The filter is clipped to the glass shape.
//
// Model, measured on Apple's native iOS 26 glass: the sample point moves only
// INWARD, along the inward normal of the rounded-rect distance field (radial at
// the corner arcs, no tangential part). With t the distance from the edge,
//   source = p + d(t) * n_in,
//   d(t) = A * (1 - sqrt(1 - (1 - t/W)^2))   for t < W, else 0,
// so content from deeper inside is compressed into the rim, and content
// outside the glass is never pulled in. d is capped at 0.75 * A.
//
// FlutterFragCoord() is in physical pixels of the whole render target (not
// relative to the clip), and uSize is the size of the whole render target.
// Both are consistent with uRect, which the caller gives in the same pixels.

uniform vec2 uSize;         // floats 0-1: input texture size (set by the engine)
uniform vec4 uRect;         // floats 2-5: glass rect left, top, width, height (physical px)
uniform float uRadius;      // float 6: corner radius in px
uniform float uWidth;       // float 7: W, width in px of the refracting edge band
uniform float uAmount;      // float 8: A, displacement scale in px
uniform float uLift;        // float 9: brightness added to the blurred backdrop (0..1)
uniform sampler2D uTexture; // the (blurred) backdrop

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
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 grad;
  float d = shapeSdf(fragCoord, grad);

  float w = max(uWidth, 1e-3);
  float t = max(-d, 0.0);
  float disp = 0.0;
  if (t < w) {
    float k = 1.0 - t / w;
    disp = min(uAmount * (1.0 - sqrt(max(1.0 - k * k, 0.0))), 0.75 * uAmount);
  }
  // Inward = against the outward gradient.
  vec2 src = fragCoord - grad * disp;
  vec4 c = texture(uTexture, clamp(src / uSize, vec2(0.0), vec2(1.0)));
  fragColor = vec4(min(c.rgb + uLift * c.a, vec3(1.0)), c.a);
}
