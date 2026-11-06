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
  // t: 0 in the flat centre, 1 at the very edge.
  float t = clamp(1.0 - depth / thick, 0.0, 1.0);

  // Bevel profile: a rounded (quarter-circle) lip. Zero in the centre, grows
  // smoothly and steeply toward the edge, like a thick glass slab.
  float prof = 1.0 - sqrt(max(1.0 - t * t, 0.0));
  float maxShift = 0.8 * thick * uRefraction;
  vec2 inward = -grad;
  vec2 offset = inward * prof * maxShift;

  // Subtle chromatic dispersion: red/blue sample slightly different distances.
  float disp = 0.06 * prof;
  vec3 col;
  col.r = sampleBackdrop(fragCoord, offset * (1.0 - disp)).r;
  col.g = sampleBackdrop(fragCoord, offset).g;
  col.b = sampleBackdrop(fragCoord, offset * (1.0 + disp)).b;

  // Lighting. Light comes from the top-left: outward normals facing it are lit,
  // those facing bottom-right get a weaker secondary highlight.
  vec2 lightDir = normalize(vec2(-1.0, -1.0));
  float facing = dot(grad, lightDir);            // +1 top-left, -1 bottom-right
  float rimMask = smoothstep(0.0, 1.0, t);       // 0 centre, 1 edge
  float thin = pow(t, 3.0);                      // concentrates on the very edge
  float spec = (max(facing, 0.0) + 0.55 * max(-facing, 0.0));
  float rim = spec * (0.35 * rimMask * rimMask + 0.65 * thin) * uHighlight;
  col += vec3(rim * 0.55);

  // Faint inner darkening opposite the light, just inside the edge band.
  float shade = max(-facing, 0.0) * rimMask * rimMask * 0.06 * uHighlight;
  col *= 1.0 - shade;

  // Thin bright hairline at the boundary for definition.
  float hair = (1.0 - smoothstep(0.0, 1.5, depth)) * 0.08 * uHighlight;
  col += vec3(hair);

  fragColor = vec4(mix(base.rgb, clamp(col, 0.0, 1.0), cover), 1.0);
}
