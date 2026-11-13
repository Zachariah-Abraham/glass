# tasks.md

Current state and pending work only. **Keep it short:** when something is done, delete it (the
commit history and `CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute
dates. See AGENTS.md §1.

_Last updated: 2026-11-10_

## Current state
- **glass 2.4.0** (2026-11-09, release PR #26, tag `v2.4.0`, `publish.yml` succeeded) is the latest
  release. It adds `LiquidGlass.precache()`. 2.3.0 (2026-11-07) added experimental liquid glass and
  raised the minimum to Flutter 3.29 / Dart 3.7. Releases are automated (AGENTS.md §6).
- Root and `example/` analyze clean and tests pass on Flutter 3.50.0 (FVM `stable`) and 3.29.0, with and without
  `--enable-impeller` (`--exclude-tags golden`).

## Pending (not started)
- Release PR #33 (`chore(main): release 2.5.0`, open) releases `grouped`, the faster liquid
  backdrop (#31) and liquid bending along `clipper` / per-corner radii (#30). Merging it publishes
  2.5.0; that is the human's decision. Merge it before #28, or release-please folds both into 3.0.0.
- Measured on one Android phone (Adreno, Vulkan, 90 Hz), raster per frame for a list of cards,
  ungrouped vs `grouped: true`: liquid regular 14.0 vs 4.5 ms, liquid clear 11.8 vs 4.3 ms, plain
  4.9 vs 2.5 ms. The probe app used is not in the repo.
- Liquid glass gaps:
  - continuous ("squircle") corners: opt-in only, deprioritized;
  - shape merging (like SwiftUI's `GlassEffectContainer`): deferred until users ask;
  - not yet checked on Skia or on iOS devices (checked on one Android phone).
- 3.0.0 (next major): delete the deprecated `clipBehaviour` alias (use a `feat!:` commit or a
  `BREAKING CHANGE:` footer). No other 3.0.0 changes are decided.
- PR #29 (`ci:`, open, CI green) makes `publish.yml` run in the GitHub environment `pub.dev` and
  documents the `v*` tag ruleset. The ruleset and environment already exist on GitHub. The human has
  not approved merging it (it changes the publish pipeline), and still has to enable "Require GitHub
  Actions environment" on pub.dev afterwards. PR #28 (`feat!:`, 3.0.0) waits for the 2.5.0 release.
- The merged branch `spike/liquid-glass` still exists on GitHub. Delete it only if the human asks.
