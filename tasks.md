# tasks.md

Current state and pending work only. **Keep it short:** when something is done, delete it (the
commit history and `CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute
dates. See AGENTS.md §1.

_Last updated: 2026-11-10_

## Current state
- **glass 2.4.0** (2026-11-09, release PR #26, tag `v2.4.0`, `publish.yml` succeeded) is the latest
  release. It adds `LiquidGlass.precache()`. 2.3.0 (2026-11-07) added experimental liquid glass and
  raised the minimum to Flutter 3.29 / Dart 3.7. Releases are automated (AGENTS.md §6).
- Root and `example/` analyze clean and tests pass on Flutter 3.47.7 (FVM `stable`), with and without
  `--enable-impeller` (`--exclude-tags golden`).

## Pending (not started)
- Branch `feat/liquid-clip-shape`: liquid glass bending and rim now follow `clipper` and per-corner
  (elliptical) radii (PR #30, open). Tests in `test/liquid_shader_test.dart`.
- Branch `perf/liquid-backdrop`, stacked on #30 (merge #30 first): Android phone performance.
  - `fix:` the blur and the shader are separate backdrop filters, not `ImageFilter.compose`: a
    list of `LiquidGlass.clear` cards went from about 20 ms to 7 ms raster per frame at 60 Hz.
  - `feat:` `asGlass(grouped: true)` shares the nearest `BackdropGroup`'s backdrop. At 90 Hz (phone
    refresh while touching) a list of liquid regular cards went from 14.0 ms (drops most frames) to
    4.5 ms, liquid clear from 11.8 to 4.3 ms, plain from 4.9 to 2.5 ms.
  - The reported startup "freeze" came from the `flutter drive` test harness. In the real app the
    first frames cost about 150-230 ms of pipeline creation.
  - The probe app used for the measurements (`perf_probe.dart`, untracked) is not in the repo.
- Liquid glass gaps:
  - continuous ("squircle") corners: opt-in only, deprioritized;
  - shape merging (like SwiftUI's `GlassEffectContainer`): deferred until users ask;
  - not yet checked on Skia or on iOS devices (checked on one Android phone, see above).
- 3.0.0 (next major): delete the deprecated `clipBehaviour` alias (use a `feat!:` commit or a
  `BREAKING CHANGE:` footer). No other 3.0.0 changes are decided.
- Backlog, not approved: harden automated publishing (tag protection for `v*`, a required `pub.dev`
  environment; AGENTS.md §6). Deferred by the human.
- The merged branch `spike/liquid-glass` still exists on GitHub. Delete it only if the human asks.
