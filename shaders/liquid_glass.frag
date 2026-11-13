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
// The shape is evaluated in the glass's own (local, logical) coordinates, so
// it stays right under rotated, skewed or perspective ancestors.
// FlutterFragCoord() is in physical pixels of the whole render target (not
// relative to the clip), and uSize is the size of the whole render target.
// uInv* maps those pixels to local coordinates and uFwd* maps back; both are
// 3x3 projective matrices given as rows, applied to (x, y, 1).

uniform vec2 uSize;         // floats 0-1: input texture size (set by the engine)
uniform vec4 uRect;         // floats 2-5: the glass shape's rect in local logical px (left, top, right, bottom)
uniform vec4 uRadiiX;       // floats 6-9: corner radii along x (top-left, top-right, bottom-right, bottom-left)
uniform vec4 uRadiiY;       // floats 10-13: corner radii along y, same order
uniform float uWidth;       // float 14: W, width of the refracting edge band (local px)
uniform float uAmount;      // float 15: A, displacement scale (local px)
uniform vec3 uInv0;         // floats 16-24: screen physical px -> local, rows
uniform vec3 uInv1;
uniform vec3 uInv2;
uniform vec3 uFwd0;         // floats 25-33: local -> screen physical px, rows
uniform vec3 uFwd1;
uniform vec3 uFwd2;
uniform float uLift;        // float 34: brightness added to the blurred backdrop (0..1)
uniform float uMid;         // float 35: mid-tone lift of the blurred backdrop (x += uMid * x * (1 - x))
uniform vec3 uTint;         // floats 36-38: tint color (0..1, not premultiplied)
uniform float uTintMix;     // float 39: tint strength (0..1)
uniform float uSat;         // float 40: saturation of the blurred backdrop (1 = unchanged)
uniform float uHighlight;   // float 41: rim intensity (1 = native)
uniform sampler2D uTexture; // the (blurred) backdrop

out vec4 fragColor;

// Signed distance to the glass's rounded rect (negative inside), whose corners
// can each have their own elliptical radius. Also returns the outward gradient
// in `grad`. A future version can replace this with a smooth-min union of
// several shapes as long as it keeps returning (distance, gradient).
float shapeSdf(vec2 p, out vec2 grad) {
  vec2 half_ = (uRect.zw - uRect.xy) * 0.5;
  vec2 c = p - (uRect.xy + half_);
  // The radii of the corner in this point's quadrant.
  vec2 r = c.y < 0.0
      ? (c.x < 0.0 ? vec2(uRadiiX.x, uRadiiY.x) : vec2(uRadiiX.y, uRadiiY.y))
      : (c.x < 0.0 ? vec2(uRadiiX.w, uRadiiY.w) : vec2(uRadiiX.z, uRadiiY.z));
  r = clamp(r, vec2(0.0), half_);
  // q: position relative to the corner's centre, mirrored into the quadrant.
  vec2 q = abs(c) - (half_ - r);
  vec2 g;
  float d;
  if (q.x > 0.0 && q.y > 0.0) {
    if (min(r.x, r.y) < 1e-3) {
      // Sharp corner.
      d = length(q);
      g = q / max(d, 1e-5);
    } else {
      // Elliptical arc. Approximate distance (exact for circles): the
      // ellipse's implicit function divided by its gradient's length.
      vec2 qr = q / r;
      vec2 qrr = q / (r * r);
      float k0 = length(qr);
      float k1 = max(length(qrr), 1e-5);
      d = k0 * (k0 - 1.0) / k1;
      g = qrr / k1;
    }
  } else {
    // Along a straight edge: the nearer of the two sides.
    vec2 e = q - r;
    d = max(e.x, e.y);
    g = e.x > e.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  }
  grad = g * sign(c + vec2(1e-5));
  return d;
}

vec2 toLocal(vec2 s) {
  vec3 h = vec3(s, 1.0);
  return vec2(dot(uInv0, h), dot(uInv1, h)) / dot(uInv2, h);
}

vec2 toScreen(vec2 l) {
  vec3 h = vec3(l, 1.0);
  return vec2(dot(uFwd0, h), dot(uFwd1, h)) / dot(uFwd2, h);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 p = toLocal(fragCoord);
  vec2 grad;
  float d = shapeSdf(p, grad);

  float w = max(uWidth, 1e-3);
  float t = max(-d, 0.0);
  float disp = 0.0;
  if (t < w) {
    float k = 1.0 - t / w;
    disp = min(uAmount * (1.0 - sqrt(max(1.0 - k * k, 0.0))), 0.75 * uAmount);
  }
  // Inward = against the outward gradient, then back to screen pixels.
  vec2 src = toScreen(p - grad * disp);
  // Distance from the edge in screen pixels, for the rim: the local distance
  // divided by how fast it changes per screen pixel here.
  vec2 dx = toLocal(fragCoord + vec2(1.0, 0.0)) - p;
  vec2 dy = toLocal(fragCoord + vec2(0.0, 1.0)) - p;
  float perPx = length(vec2(dot(dx, grad), dot(dy, grad)));
  float tPx = t / max(perPx, 1e-5);
  vec4 c = texture(uTexture, clamp(src / uSize, vec2(0.0), vec2(1.0)));
  vec3 rgb = c.a > 0.0 ? c.rgb / c.a : c.rgb;
  // Measured on Apple's glass (sRGB values): saturate around the Rec. 709
  // luma, then the mid-tone lift and lift, then the tint. Saturation can go
  // below 0 or above 1 here; only the result is clamped.
  float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
  rgb = luma + uSat * (rgb - luma);
  rgb += uMid * rgb * (1.0 - rgb) + uLift;
  rgb = clamp(mix(rgb, uTint, uTintMix), 0.0, 1.0);

  // The rim, measured on Apple's glass over uniform colors (the same for clear
  // and regular, all around the shape, no light direction): over the first
  // three physical pixels inside the edge, mix in white by a = 0.65, 0.47,
  // 0.29, then saturate the result by 1 + 6.3 a^2 around its luma. So it is
  // white over grey but takes on the color behind it over saturated colors
  // (yellowish over orange, a deeper green over green).
  float a = max(0.735 - 0.178 * tPx, 0.0) * (1.0 - smoothstep(3.0, 3.3, tPx));
  a = clamp(a * uHighlight, 0.0, 1.0);
  rgb = mix(rgb, vec3(1.0), a);
  float rimLuma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
  rgb = clamp(rimLuma + (1.0 + 6.3 * a * a) * (rgb - rimLuma), 0.0, 1.0);

  fragColor = vec4(rgb * c.a, c.a);
}
