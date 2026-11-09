# tasks.md

Current state and pending work only. **Keep it short:** when something is done, delete it (the
commit history and `CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute
dates. See AGENTS.md §1.

_Last updated: 2026-11-09_

## Current state
- **glass 2.4.0** (2026-11-09, release PR #26, tag `v2.4.0`, `publish.yml` succeeded) is the latest
  release. It adds `LiquidGlass.precache()`. 2.3.0 (2026-11-07) added experimental liquid glass and
  raised the minimum to Flutter 3.29 / Dart 3.7. Releases are automated (AGENTS.md §6).
- Root and `example/` analyze clean and tests pass on Flutter 3.47.7 (FVM `stable`), with and without
  `--enable-impeller` (`--exclude-tags golden`).

## In progress / pending
- Liquid glass gaps:
  - the shader ignores `clipper` and non-uniform radii;
  - continuous ("squircle") corners: opt-in only, deprioritized;
  - shape merging (like SwiftUI's `GlassEffectContainer`): deferred until users ask;
  - not yet checked on real devices (performance) or on Skia.
- 3.0.0: branch `feat/remove-clip-behaviour` removes the deprecated `clipBehaviour` parameter
  (`feat!:`, so release-please will propose 3.0.0). Merging the release PR is the human's decision.
- Backlog, not approved: harden automated publishing (tag protection for `v*`, a required `pub.dev`
  environment; AGENTS.md §6). Deferred by the human.
