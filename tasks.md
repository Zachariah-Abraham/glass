# tasks.md

Current state and pending work only. **Keep it short:** when something is done, delete it (the
commit history and `CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute
dates. See AGENTS.md §1.

_Last updated: 2026-11-15_

## Current state
- **glass 3.0.1** (2026-11-14, tag `v3.0.1`, `publish.yml` succeeded) is the latest release; it
  keeps `LiquidGlass.clear` visible without shader support. 3.0.0 (2026-11-13) removed the deprecated `clipBehaviour`. 2.5.0 (same day) added `asGlass(grouped:)`, faster liquid
  glass on Android and liquid bending along `clipper` / per-corner radii. Releases are automated
  (AGENTS.md §6). Publishing hardening is complete: `publish.yml` runs in the `pub.dev` environment
  and pub.dev requires it.
- Root and `example/` analyze clean and tests pass on Flutter 3.50.0 (FVM `stable`) and 3.29.0, with and without
  `--enable-impeller` (`--exclude-tags golden`).

## Pending (not started)
- Measured on one Android phone (Adreno, Vulkan, 90 Hz), raster per frame for a list of cards,
  ungrouped vs `grouped: true`: liquid regular 14.0 vs 4.5 ms, liquid clear 11.8 vs 4.3 ms, plain
  4.9 vs 2.5 ms. The probe app used is not in the repo.
- Liquid glass gaps:
  - continuous ("squircle") corners: opt-in only, deprioritized;
  - shape merging (like SwiftUI's `GlassEffectContainer`): deferred until users ask;
  - checked on one Android phone (Impeller/Vulkan) and the iOS simulator (iPhone 17 Pro, Impeller/Metal,
    2026-11-14: plain, clear and regular all render correctly). Not yet checked on a real iPhone, on
    Android with Skia (`--no-enable-impeller`), or on real web hardware;
  - the web/Skia fallback (no shader support) draws a faint 8% tint and a 1 px light border so
    `LiquidGlass.clear` stays visible; still no edge bending. Not yet seen on a real Skia device.
