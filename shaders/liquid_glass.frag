#version 460 core
#include <flutter/runtime_effect.glsl>

// Refraction pass of liquid glass, used as a backdrop filter ALONE (the blur is
// a separate, later pass). It runs in a clip that is larger than the glass, so
// it can read the backdrop outside the glass shape: content just outside the
// rim is pulled in and squashed. Outside the shape it returns the backdrop
// unchanged, so the larger clip is invisible.
//
// Measured on macOS (Impeller/Metal): FlutterFragCoord() is in physical pixels
// of the whole render target (not relative to the clip), and uSize is the size
// of the whole render target. Both are used consistently with uRect, which the
// caller gives in the same global physical pixels.

uniform vec2 uSize;         // floats 0-1: input texture size (set by the engine)
uniform vec4 uRect;         // floats 2-5: glass rect left, top, width, height (physical px)
uniform float uRadius;      // float 6: corner radius in px
uniform float uThickness;   // float 7: width in px of the curved edge band
uniform float uRefraction;  // float 8: refraction strength, ~1 = default
uniform sampler2D uTexture; // the backdrop

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

vec3 sampleBackdrop(vec2 p) {
  return texture(uTexture, clamp(p / uSize, vec2(0.0), vec2(1.0))).rgb;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec4 base = texture(uTexture, fragCoord / uSize);

  vec2 grad;
  float d = shapeSdf(fragCoord, grad);

  // ~1px antialiased coverage of the shape. Outside it the pixel is untouched.
  float cover = 1.0 - smoothstep(-0.5, 0.5, d);
  if (cover <= 0.0) {
    fragColor = base;
    return;
  }

  float thick = max(uThickness, 1.0);
  float depth = max(-d, 0.0);
  // u: 0 in the flat centre, 1 at the very rim.
  float u = clamp(1.0 - depth / thick, 0.0, 1.0);

  // Dome profile: a quarter circle, flat in the centre and infinitely steep at
  // the rim. The sample point moves toward the outside, so content near the rim
  // (and, at the rim itself, content from up to `off` px beyond it) is
  // squeezed into the edge band, as in a thick convex slab.
  float prof = 1.0 - sqrt(max(1.0 - u * u, 0.0));
  float off = 0.7 * thick * uRefraction * prof;
  vec3 col = sampleBackdrop(fragCoord + grad * off);

  fragColor = vec4(mix(base.rgb, col, cover), 1.0);
}
