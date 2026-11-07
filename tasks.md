# tasks.md

Living status of work on this repo. **Update it whenever you make progress** (see AGENTS.md §1).
Newest information goes first in each section. Use absolute dates.

_Last updated: 2026-11-07_

## Current state
- **glass 2.2.0 is published on pub.dev** (2026-11-06, adds `clipBehavior`). `main` is at or ahead of the
  `v2.2.0` tag.
- Release flow is fully automated (AGENTS.md §6): Conventional Commits on `main` → release-please
  opens a release PR → the human merges it → `vX.Y.Z` tag → `publish.yml` publishes to pub.dev.
  - Requires the `RELEASE_PLEASE_TOKEN` Actions secret (set) and pub.dev automated publishing for
    `Zachariah-Abraham/glass` with tag pattern `v{{version}}` (enabled).
- With Flutter 3.47.7 / Dart 3.13.5 (FVM `stable`): root and `example/` `flutter analyze` are
  clean, and `flutter test` passes in both (root: `test/glass_widget_test.dart`, goldens, and the
  Impeller-only `test/liquid_shader_test.dart`; example: glass toggle and liquid switch tests).
- `pubspec.yaml` `version:` is managed by release-please. Don't edit it by hand, and keep it as
  plain `x.y.z` (no `+N`).

## In progress
- Apple "liquid glass" support, **spike on branch `spike/liquid-glass`** (not for merging as is).
  Human decisions 2026-11-06: extend `asGlass` itself (an optional config, not a new method; a
  breaking release is acceptable if that turns out to be necessary); try to keep the 3.27 minimum and
  raise it only if needed; shape merging ("blobs" like SwiftUI's `GlassEffectContainer`) is wanted,
  but must be our own implementation. 2026-11-07: the human lifted the no-reading rule; reading
    `liquid_glass_renderer` (Apache-2.0) and `liquid_glass_widgets` (MIT) is fine now. Copying code would
    still need their licence notices (that is why flutter/packages#13163 was reverted), so keep ours original.
  - Done in the spike: `LiquidGlass` settings class (`thickness`, `refraction`, `highlight`) and an
    `asGlass(liquid:)` parameter, default null = unchanged rendering. `shaders/liquid_glass.frag`
    (rounded-rect SDF, edge refraction, rim highlight, slight dispersion; blur is composed in Dart
    via `ImageFilter.compose(outer: ImageFilter.shader(..), inner: blur)`). A private render object
    pushes a `BackdropFilterLayer` and passes the glass rect in global physical pixels.
  - Verified on the iOS simulator (iPhone 17 Pro, Impeller/Metal) with a scratchpad demo app: edges
    visibly bend the backdrop and the rim highlight shows. So `FlutterFragCoord()` in a backdrop
    shader is global physical pixels there. Not yet checked on Android (Vulkan/GLES: y may flip).
  - 2026-11-07: compared with native SwiftUI `.glassEffect` on the same simulator (same scene, same
    rects; reference app and screenshots in the session scratchpad, not in the repo). Ours is closest
    to `Glass.clear`. Differences: native refraction is stronger and spans most of a capsule's height
    (content near the edge is squeezed into thin slivers), ours bends only a 20 pt band; native rim is
    a crisp ~1 px light hairline, ours is a soft glow plus a darkened edge; `Glass.regular` is a heavy
    milky frost (strong blur, light tint) that we can't match with the fixed 10% tint. Native merge
    (`GlassEffectContainer(spacing: 40)`, 10 pt gap) gives one peanut shape with a smooth concave
    waist; at a 70 pt gap the shapes stay separate.
  - 2026-11-07 FIXED stale glass rect while scrolling. Two causes: (1) an ancestor (for example a
    scroll view moving a repaint boundary) moves the glass without repainting it, so paint-time uniforms
    go stale; (2) the engine copies a shader's uniforms the first time a filter object is pushed
    (`_FragmentShaderImageFilter.nativeFilter` is a cached `late final`), so `setFloat` on an existing
    filter has no effect. (Dragging only worked because every rebuild made a new blur and filter.)
    Composition callbacks don't help: they run after `addToScene`. Fix: the live path uses
    `_LiquidBackdrop`/`_RenderLiquidBackdrop`, which pushes a `_LiquidBackdropLayer` (a
    `BackdropFilterLayer` with `alwaysNeedsAddToScene`). Right before each push it computes all uniforms
    (rect from `getTransformTo(null)`, so scaled ancestors are handled too; rotation isn't) and builds a
    new `compose(shader, blur)` filter only if they changed. Its ancestors are re-added every frame; siblings
    and children stay retained, and an idle screen schedules no frames. `_RenderLiquidGlassLayers` now only
    paints the shadow. Verified on the simulator with a scratchpad scroll scene (`lg_demo` `SCROLL=start:jump`,
    `scroll_shot.sh`): after a jump the glass is pixel-identical to opening at that offset (before: off by up
    to 255); static scenes unchanged. No widget test (shader isn't live in tests yet).
  - 2026-11-07 DONE Android check, no code change needed. Emulator `Medium_Phone_API_37.0` (1080x2400, dpr 2.625)
    with the scratchpad demo `lg_demo` (its `_MeasPainter` now reads the device dpr and size instead of assuming the
    iPhone). The emulator picks Impeller **OpenGLES** by default; Vulkan was forced with
    `<meta-data android:name="io.flutter.embedding.android.ImpellerBackend" android:value="vulkan" />` in the demo's
    `AndroidManifest.xml`. On both backends `FlutterFragCoord()` in the backdrop shader is global physical px with
    y down (no flip). Decoded from hue-coded backgrounds, the inward bend on all four sides of a 300x180 card and a
    260x80 pill matches the model `d(t)` within ~1-2 pt for t >= 2 pt (the rim pixel at 1.5 pt is off by up to 5 pt
    because the rim changes its colour and hue), and the rim lines up with the clip. GLES and Vulkan
    are practically pixel-identical (mean diff < 1.4/255 inside the glass). The scroll scene (`SCROLL=0:300` vs
    `300:300`) is pixel-identical on both. The regular preset (tint, shadow) renders as on iOS.
    Script: scratchpad `and_shot.sh`, data in scratchpad `android/`. Not checked: real devices, and Skia
    (no Impeller).
  - 2026-11-07 DONE rotation, skew and perspective. `_RenderLiquidBackdrop._uniforms` now sends the glass's local
    size, radius, W and A in local logical px plus two row-major 3x3 projective matrices (rows x, y, w and columns x,
    y, translation of `dpr * getTransformTo(null)`): screen physical px → local (uniforms 7-15, inverted in Dart by
    `_invert3`; a singular matrix gives zeros) and local → screen (16-24). `liquid_glass.frag` maps
    `FlutterFragCoord()` to local space, evaluates the SDF and inward bend there and maps the sample point back. The
    rim's 3 px width stays in screen pixels (local distance divided by its per-screen-pixel rate). The other
    uniforms moved to 25-32. Verified on the Android emulator (GLES and Vulkan) and the iOS simulator with
    the demo's `XF=rot:20|skew:0.3|persp:35` mode (whole scene transformed): rim and bend follow the real edges
    (before: the screen-space bounding box). A 20° rotated scene matches the unrotated screenshot rotated by 20°
    up to resampling noise (pixels off by > 40/255 in the card: 5093 old, 322 new). Unrotated scenes and the
    scroll scene are unchanged (max diff 3/255). Rotated rim covered by `test/liquid_shader_test.dart`.
  - 2026-11-07 DONE shader-path tests: `test/liquid_shader_test.dart`, run with
    `flutter test --enable-impeller` (skipped otherwise). It covers: the live path replaces the plain
    `BackdropFilter`; the rim is lit just inside the edge over black, for an unrotated card and a card
    rotated by 30°; and the filter is reused while nothing moves but rebuilt after a scroll moves the
    glass's repaint boundary (it fails if `_LiquidBackdropLayer.alwaysNeedsAddToScene` is false). In the
    package's own tests the shader asset only exists as `shaders/liquid_glass.frag`, so the test copies
    it to `build/unit_test_assets/packages/glass/...`. Found and fixed along the way: `_GlassBackdropState`
    now caches the loaded program in the static `_loadedProgram`, so later glass widgets use the shader
    from their first frame (before, each one showed one frame of plain blur, and in tests the callback
    on the static future never ran after the first test because it was scheduled in that test's
    fake-async zone). The `glass_widget_test.dart` liquid group is now "liquid without shader support"
    and is skipped under Impeller. CI runs them in a "Test with Impeller" step on 3.29.0 and stable
    (works on Linux; `GLASS_REQUIRE_SHADER=1` makes a guard test fail if shader filters are unavailable,
    so the step can't pass by skipping).
  - 2026-11-07 STATUS: every before-release item is done; PR #16
    (https://github.com/Zachariah-Abraham/glass/pull/16) all CI green. The human approved merging it as a
    **squash** with the subject `feat: add experimental liquid glass option (requires Flutter 3.29 or newer)` and a
    plain body (the branch has ~15 spike-era `feat:`/`fix:` commits that must not reach the changelog). The pub.dev
    example (`example/lib/main.dart`) has a "Liquid glass" switch (`LiquidGlass.clear`). Gallery app
    `example/lib/gallery.dart` (`flutter run -t lib/gallery.dart`, 8 stories over an animated background, mouse
    drag scrolls) verified on the iOS simulator (Metal), Android emulator (GLES), macOS (Impeller MetalSDF) and
    Chrome (fallback). NEXT: after the merge, check release-please's 2.3.0 release PR (changelog text) and run
    `pub publish --dry-run` on `main`; merging the release PR (= publishing) is the human's. Then a public,
    presentable recording of liquid glass for the PR and a LinkedIn post (the human reviews it first).
  - Known gaps: `clipper` and non-uniform radii are ignored by the shader; merging not started.
  - 2026-11-07 DONE minimum raised to Flutter 3.29.0 / Dart 3.7 (allowed by the human). Checked the
    engine sources: 3.27.0's `dart:ui` (engine 83bacfc5) has no `ImageFilter.shader` or
    `isShaderFilterSupported`; 3.29.0's has both (web: `isShaderFilterSupported` is false, so web keeps
    the plain blur). On 3.29.0 locally: root and example analyze clean, tests pass with and without
    `--enable-impeller` (the rim is dimmer there than on 3.47, 87 vs ~166 over black, so the rim tests
    compare it to the interior). Updated `pubspec.yaml`, `example/pubspec.yaml`, the CI matrix
    (3.27.0 → 3.29.0), README and AGENTS.md. Dart 3.7 switched `dart format` to the tall style, so
    the same commit reformats lib/, test/ and example/.
  - Prior art: `liquid_glass_renderer` (needs Flutter 3.47 + Flutter GPU). Flutter's own Cupertino work:
    flutter/flutter#170310.
  - 2026-11-07: presets `LiquidGlass.regular` / `LiquidGlass.clear` added (explicit `blurX`, `blurY`,
    `tintColor`, `frosted` override the preset; those params are now nullable) and covered by a
    `group('liquid')` in `test/glass_widget_test.dart`. Shader tuned against native screenshots: dome
    bend in a 40 pt band (`edgeWidth: 40` on both presets), crisp ~1-3 px hairline rim, no dispersion
    or edge darkening. Measured: native clear *brightens* the dark scene (~9% white), regular is a
    near-opaque light blue-grey (~(177,193,199)). (Superseded: the first tuning mirrored content from
    inside the glass near the rim; fixed by the restructure below.) Also `copyWith` can't reset
    `edgeWidth` to null.
  - 2026-11-07, in progress: human decision: the mirrored rim is NOT acceptable; match native exactly,
    including at screen edges and corners. Two parallel tasks: (a) measure native pull-in distance,
    bend profile, corner direction and screen-edge behaviour with a test-pattern scene (iOS simulator);
    (b) 2026-11-07, superseded: restructured the liquid path to sample an inflated backdrop (shader-only backdrop
    layer over the glass rect + margin, passing through outside the shape, then a blur clipped to the
    glass, then the rim drawn on top), tested on macOS desktop. Then tune (b) to (a)'s model.
    2026-11-07 native measurements (hue-encoded coordinate backgrounds decoded per pixel; data in the
    session scratchpad `edge/`): native samples INWARD only, along the inward SDF normal (radial at
    corners, no tangential part). Content outside the glass is never pulled in. Content from deeper
    inside is compressed into the rim, so straight lines wrap into loops at the edge. Model:
    `source = p + d(t)*n_in`, `W = min(20 pt, 0.69*min(w,h)/2)`, `A = 3W`,
    `d(t) = A*(1 - sqrt(1 - (1 - t/W)^2))` for t < W. Measured for a 260x80 pill: d = 42/34.7/29/20.3/
    12.5/5.3/1.5/0 at t = 1/2/3/5/8/12/16/20 pt. It is the same for cards, for regular vs clear, and at or past screen
    edges and corners (no fade, clamping or rim change). DONE: shader now implements this inward model
    (`edgeWidth: null` = automatic W, `refraction: 1.0` = native, `LiquidGlass.clear` blur 1.5). Decoded
    on the simulator, ours is within ~1 pt of native at every depth for a pill, card, 120x44 shape,
    top-left screen corner and partly off-screen glass. Structure is 2 passes: one `BackdropFilter`
    in the `ClipRRect` with `compose(outer: shader, inner: blur)` (blur first, then inward refraction,
    no margin), then `shaders/liquid_rim.frag` painted last. Photometry fitted 2026-11-07 from native deep-interior
    pixels (scripts in scratchpad `fit/`): regular = blur ~6.7 pt then `0.26*in + (176,184,188)`, i.e.
    tint `0xEEF7FB` at 74% (flat, no gradient); clear = blur ~1.5 pt plus an additive lift of +22/255
    (new `LiquidGlass.lift`, shader uniform 9). Rim (`liquid_rim.frag`): white, ~1 pt (3 px) wide,
    additive alpha 0.55/0.41/0.26 over the first 3 px, the same at every angle (no light direction);
    `highlight` 1.0 = native. In liquid mode the tint gradient is flat. Card matches native within
    ~3/255 over flat areas. Text clarity (2026-11-07): with a pixel-identical
    background (the demo can show native's no-glass screenshot), the band is not sharper than native;
    the earlier impression came from different fonts and wrapping in the two demo scenes. The clear
    interior was ~10% too sharp; fixed with clear blur 1.5 → 1.6. Blur order checked: native also
    blurs before refracting. Regular on the aligned scene: native lets text slivers show with more
    contrast and the pill is ~5 levels darker than ours.
  - 2026-11-07 polish pass (measured over uniform black/grey/white and the aligned scene; crops in
    scratchpad `polish/`): the "darker rim pixel over white" was a misreading. Native's rim is a
    backdrop-independent white overlay, alpha ~0.65/0.47/0.29 on the first 3 px, no dark outline, same
    for both presets; `liquid_rim.frag` now uses that. Native regular casts a multiplicative shadow
    (~8.6% black, sigma ~15 pt, y +8 pt; clear has none): new `LiquidGlass.shadow` (`BoxShadow?`),
    painted by `_RenderLiquidGlassLayers._paintShadow` outside the shape only, no layout/hit-test
    change. New `LiquidGlass.midtoneLift` (shader uniform 10, `x += m*x*(1-x)`), used only by clear
    (0.086, with lift 0.0745). Regular is now tint `0xF2F8FB` at 0.735. Aligned-scene luminance native
    vs ours: clear card 120.3/120.8, clear pill 72.9/75.0, regular card 208.4/208.5, regular pill
    190.1/195.8. Remaining: regular over white is slightly bluish (244/248/250 vs neutral 250; native
    chroma depends on the backdrop, so one tint can't match both); regular pill ~5 levels too light
    (size-dependent, not modelled); native regular shows more sliver contrast in the edge band;
    shadow ~1% weak on the pill.
  - 2026-11-07 saturation fix: native regular's tint is neutral; the blue came from a saturation boost
    of the backdrop. Fitted on 19 native uniform-colour refs (`native/ref_hex*.png`, `ref_lv*`; script
    scratchpad `sat/fit.py`, rms 2.2/255): saturate around Rec. 709 luma by 2.32, mid-tone lift 0.242,
    then mix with 0xF7F7F7 at 0.731. Clear has no saturation (fit 0.99). New `LiquidGlass.saturation`
    (default 1.0) and shader uniforms 11-15 (tint rgb, tint strength, saturation). The tint is now done
    IN the shader on the live liquid path (saturated values go below 0 before the tint, so a separate
    tint layer would clamp them); `_GlassBackdrop` builds the tint/noise `Container` and drops its
    gradient only when the shader is live (fallback and tests unchanged). Verified on the simulator:
    over white 249 (native 250, was bluish 244/248/250), over red/blue/teal/orange within ~4. Aligned
    regular card (210.7,219.5,223.1) vs native (206.7,217.6,222.2); pill still ~3-8 lighter (size
    dependence).
  - 2026-11-07 backdrop-coloured rim: native's rim takes on the colour behind it (yellowish over orange,
    deeper green over green). Fitted on the uniform refs (scratchpad `sat/rim.py`, rms 2.3/255 vs 32.8
    for a white-only rim): mix in white by `a = 0.735 - 0.178*t` over the first 3 physical px
    (0.65/0.47/0.29), then saturate by `1 + 6.3*a^2` around luma. The rim now lives in
    `shaders/liquid_glass.frag` (it needs the backdrop), `highlight` is uniform 16, and
    `shaders/liquid_rim.frag` and its second paint pass are gone. So the rim now draws under the
    child and noise instead of over them. Verified on the simulator (scratchpad `rimc/cmp.py`):
    regular rim within ~4/255 rms of native over 8 colours (yellow's innermost px is off by up to 27).
  - Corner shape: native rounded rects use continuous ("squircle") corners
    (`RoundedRectangle(style: .continuous)`); ours are circular. This changes the outline and the bend
    direction near corners (native at 20° around the corner bends at ~32°, ours 20°; up to ~8 pt
    difference in source position at the rim), which is why L and i merge at the card's corner
    natively. Pills are unaffected. Human decision 2026-11-07: add continuous corners as an **opt-in**
    option (default stays circular). Principle: we model the *effect*; platform defaults such as
    corner shape and borders stay under the caller's control even when that changes the result.
    Not implemented yet (plan: our own superellipse outline for the clip and the shader SDF, so it
    doesn't need Flutter 3.32's `ClipRSuperellipse`).
  - Earlier next steps: human reviews the tuning crops; then try sampling outside the rect, fix the stale-position
    problem, Android check, shader-path tests, and design merging.
- Renaming `clipBehaviour` to `clipBehavior`: step 1 shipped in 2.2.0 (PR #11; `clipBehaviour` is a
  `@Deprecated` alias). Step 2 (next major 3.0.0): delete `clipBehaviour`, with a `feat!:` commit or
  `BREAKING CHANGE:` footer. Other 3.0.0 candidates: none decided yet.

## Backlog (suggested, not yet approved by the human)
- [x] Issue #7 (blur disappears at scroll limits): replied and closed 2026-11-06
      (https://github.com/Zachariah-Abraham/glass/issues/7#issuecomment-6688301780); README section in
      PR #15. **Reproduced 2026-11-06** on the Android
      emulator `Medium_Phone_API_37.0` (Android 17) with the issue's layout (`asGlass` on a tall
      `Column` inside a `SingleChildScrollView`, over a striped background, default Material 3
      theme). At rest the stripes are blurred. While dragging past the top edge (held touch via
      `adb shell input motionevent DOWN/MOVE`) the blur vanishes; tint and noise stay. Cause: the
      Material 3 stretch overscroll renders the scrollable in its own layer, so the
      `BackdropFilter` has nothing behind it. Verified fix for users: wrap the scroll view in
      `ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(overscroll: false), ...)`;
      the blur then stays intact during the drag. NOTE: `ThemeData(androidOverscrollIndicator:)`
      does not exist (Flutter 3.47); `MaterialScrollBehavior` picks stretch for Material 3 and glow
      for Material 2 from `useMaterial3`. Also verified on the emulator: wrapping the scroll view in `asGlass` (glass outside, content
      scrolls inside) keeps the blur. iOS behaviour is untested. Untested workarounds: `useMaterial3: false`,
      `ClampingScrollPhysics`. Human decision 2026-11-06: this is a usage pitfall, not a package limitation, and no
      regression test is wanted (edge case). README has a "Using glass with scrolling" section.
- [ ] Optional hardening of automated publishing: GitHub tag protection rules for `v*`, and a
      required `pub.dev` environment (AGENTS.md §6).

## Done
- 2026-11-06: Merged PR #13 (7 Linux-rendered golden scenes, pinned-Flutter `golden` job, example
  web build) and PR #14 (`example/integration_test/app_test.dart`, Linux desktop `integration` job).
- 2026-11-03: Deleted `doc/api/` from git and added it to `.gitignore` and `.pubignore`.
- 2026-11-03: Merged PR #10: CI (`ci.yml`), `.pubignore` (archive ~3 MB → ~750 KB), pub.dev
  metadata (`repository`, `issue_tracker`, `topics`; shows after the next release) and
  `flutter_lints` ^5. Deleted the unused Codemagic webhook (no config, no checks).
- 2026-11-03: Released 2.1.0 (`withValues`, minimum Flutter 3.27 / Dart 3.6). First end-to-end
  automated release: release PR #9 merged, tag `v2.1.0` published to pub.dev.
- 2026-11-03: Added root `flutter_lints` config, 10 widget tests, a real example test, example
  cleanup, and the README parameters table. Analyze and tests clean.
- 2026-11-03: Added release-please (`release-please.yml`, config and manifest) and the
  tag-triggered `publish.yml`. Dropped the `+N` build suffix from `version:` so tags match
  pub.dev's `v{{version}}`.
- 2026-10-29: Added `AGENTS.md` (incl. the publishing guide in §6), `CLAUDE.md` and `tasks.md`.

## Decisions made
- 2026-11-07: liquid glass scope (human approved): keep plain glass maintained regardless; ship a narrow,
  experimental liquid option (`clear`/`regular` presets, refraction, rim, shadow). Before release: (stale
  position while scrolling: fixed 2026-11-07), (Android check: done 2026-11-07), (rotation/skew/perspective support: done),
  (shader-path tests: done), (minimum raised to 3.29: done). Continuous corners are
  deprioritized (still opt-in if ever built). Shape merging is deferred until users ask for it.
- 2026-11-06: Use Flutter's built-in goldens, not Alchemist. The scenes have no text, so Alchemist's
  font normalization isn't needed. Goldens run on one pinned Flutter version only.
- 2026-11-03: `flutter_lints` is `^5` because `^6` needs Dart 3.8 and the minimum SDK is Dart 3.6.
- 2026-11-03: Raising the minimum SDK isn't a breaking change (pub resolves users on older SDKs
  to the older release), so it ships as a minor release. Note it in a commit **subject** so it
  reaches the changelog.
- 2026-11-03: Removed the checked-in `doc/api/` (human decision, reversing an earlier keep): it's unused by pub.dev and IDEs, went stale, and shipped in the archive. Now gitignored and in `.pubignore`.
- 2026-10-29: Raising the minimum Flutter version for `withValues` is OK.

## Open questions for the human
- Do you want the remaining backlog items done? Hardening is deferred by the human.
