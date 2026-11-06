#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;         // floats 0-1: input texture size (set by the engine)
uniform vec4 uRect;         // floats 2-5: glass rect left, top, width, height (physical px)
uniform float uRadius;      // float 6: corner radius in px
uniform float uThickness;   // float 7: width in px of the curved edge band
uniform float uRefraction;  // float 8: refraction strength, ~1 = default
uniform float uHighlight;   // float 9: rim highlight intensity 0..1
uniform sampler2D uTexture; // the (already blurred) backdrop

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

vec3 sampleBackdrop(vec2 fragCoord, vec2 offset) {
  vec2 uv = clamp((fragCoord + offset) / uSize, vec2(0.0), vec2(1.0));
  return texture(uTexture, uv).rgb;
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec4 base = texture(uTexture, fragCoord / uSize);

  vec2 grad;
  float d = shapeSdf(fragCoord, grad);

  // ~1px antialiased coverage of the shape.
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
  // is squeezed into the edge band (minified), as in a thick convex slab. The
  // backdrop texture only covers the glass rect, so a sample that would land
  // outside is mirrored back inside.
  float prof = 1.0 - sqrt(max(1.0 - u * u, 0.0));
  float off = 0.7 * thick * uRefraction * prof;
  float sd = abs(depth - off);  // depth of the sampled point
  vec3 col = sampleBackdrop(fragCoord, -grad * (sd - depth));

  // Light from the top-left. Crisp ~2px hairline at the rim, a little
  // brighter on the sides facing the light.
  vec2 lightDir = normalize(vec2(-1.0, -1.0));
  float facing = dot(grad, lightDir);  // +1 top-left, -1 bottom-right
  float line = 1.0 - smoothstep(1.0, 3.0, depth);
  float spec = 0.55 + 0.45 * max(facing, 0.0) + 0.1 * max(-facing, 0.0);
  col = mix(col, vec3(0.88, 0.95, 1.0), clamp(line * spec * 1.0 * uHighlight, 0.0, 1.0));

  fragColor = vec4(mix(base.rgb, clamp(col, 0.0, 1.0), cover), 1.0);
}
