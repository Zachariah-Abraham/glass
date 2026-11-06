# tasks.md

Living status of work on this repo. **Update it whenever you make progress** (see AGENTS.md §1).
Newest information goes first in each section. Use absolute dates.

_Last updated: 2026-11-07_

## Current state
- **glass 2.1.0 is published on pub.dev** (2026-11-03). `main` is at or ahead of the `v2.1.0` tag.
- Release flow is fully automated (AGENTS.md §6): Conventional Commits on `main` → release-please
  opens a release PR → the human merges it → `vX.Y.Z` tag → `publish.yml` publishes to pub.dev.
  - Requires the `RELEASE_PLEASE_TOKEN` Actions secret (set) and pub.dev automated publishing for
    `Zachariah-Abraham/glass` with tag pattern `v{{version}}` (enabled).
- With Flutter 3.47.7 / Dart 3.13.5 (FVM `stable`): root and `example/` `flutter analyze` are
  clean, and `flutter test` passes in both (10 widget tests in `test/glass_widget_test.dart`, one
  toggle test in `example/test/widget_test.dart`).
- `pubspec.yaml` `version:` is managed by release-please. Don't edit it by hand, and keep it as
  plain `x.y.z` (no `+N`).

## In progress
- Apple "liquid glass" support, **spike on branch `spike/liquid-glass`** (not for merging as is).
  Human decisions 2026-11-06: extend `asGlass` itself (an optional config, not a new method; a
  breaking release is acceptable if that turns out to be necessary); try to keep the 3.27 minimum and
  raise it only if needed; shape merging ("blobs" like SwiftUI's `GlassEffectContainer`) is wanted,
  but must be our own implementation: don't read or copy `liquid_glass_renderer`'s source.
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
  - Known gaps: the glass rect goes stale when an ancestor moves the glass without repainting it (for
    example while scrolling); `clipper` and non-uniform radii are ignored by the shader; no tests for
    the shader path yet (`flutter test --enable-impeller` makes `isShaderFilterSupported` true, so
    widget tests can cover it); merging not started.
  - `ImageFilter.shader` is probably NOT in Flutter 3.27.0 (engine PR #53490 merged 2024-11-08, after
    the 3.27 branch point; moderate confidence). The 3.27 CI job will confirm; if so, raise the minimum
    to 3.29 (allowed by the human).
  - Prior art: `liquid_glass_renderer` (needs Flutter 3.47 + Flutter GPU). Flutter's own Cupertino work:
    flutter/flutter#170310.
  - 2026-11-07: presets `LiquidGlass.regular` / `LiquidGlass.clear` added (explicit `blurX`, `blurY`,
    `tintColor`, `frosted` override the preset; those params are now nullable) and covered by a
    `group('liquid')` in `test/glass_widget_test.dart`. Shader tuned against native screenshots: dome
    bend in a 40 pt band (`edgeWidth: 40` on both presets), crisp ~1-3 px hairline rim, no dispersion
    or edge darkening. Measured: native clear *brightens* the dark scene (~9% white), regular is a
    near-opaque light blue-grey (~(177,193,199)). Remaining difference: the backdrop texture only
    covers the glass rect, so near the rim the shader mirrors content from inside the glass (ghost
    lines of text) instead of pulling in content from outside it, as native does (squashed circles,
    text slivers). Fixing it needs a backdrop larger than the glass. Also `copyWith` can't reset
    `edgeWidth` to null.
  - Next: human reviews the tuning crops; then try sampling outside the rect, fix the stale-position
    problem, Android check, shader-path tests, and design merging.
- Renaming the misspelled public parameter `clipBehaviour` to `clipBehavior` (human decision,
  2026-11-06). Step 1 (PR on `feat/clip-behavior`): add `clipBehavior`, keep `clipBehaviour` as a
  `@Deprecated` alias, ships as a minor (2.2.0). Step 2 (later, next major 3.0.0): delete
  `clipBehaviour`, with a `feat!:` commit or `BREAKING CHANGE:` footer. Other 3.0.0 candidates: none
  decided yet.

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
