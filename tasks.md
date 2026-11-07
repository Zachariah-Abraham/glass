# tasks.md

Current state and pending work only. **Keep it short:** when something is done, delete it (the
commit history and `CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute
dates. See AGENTS.md §1.

_Last updated: 2026-11-08_

## Current state
- **glass 2.3.1** was released on 2026-11-08 (release PR #20, tag `v2.3.1`, `publish.yml` succeeded).
  It adds the pub.dev `screenshots:` gallery (weather, music, travel, photos, from `doc/screenshots/`),
  the `liquid-glass` topic and a new `description`. 2.3.0 (2026-11-07) added experimental liquid glass
  and raised the minimum to Flutter 3.29 / Dart 3.7. Releases are automated (AGENTS.md §6).
- Root and `example/` analyze clean and tests pass on Flutter 3.47.7 (FVM `stable`), with and without
  `--enable-impeller`.

## In progress
- Showcase recording and a LinkedIn post: **the human records it.** Run
  `cd example && flutter run --release -t lib/showcase.dart -d <device>`.

## Pending (not started)
- Liquid glass gaps:
  - the shader ignores `clipper` and non-uniform radii;
  - continuous ("squircle") corners: opt-in only, deprioritized;
  - shape merging (like SwiftUI's `GlassEffectContainer`): deferred until users ask;
  - not yet checked on real devices (performance) or on Skia.
- 3.0.0 (next major): delete the deprecated `clipBehaviour` alias (use a `feat!:` commit or a
  `BREAKING CHANGE:` footer). No other 3.0.0 changes are decided.
- Backlog, not approved: harden automated publishing (tag protection for `v*`, a required `pub.dev`
  environment; AGENTS.md §6). Deferred by the human.
- The merged branch `spike/liquid-glass` still exists on GitHub. Delete it only if the human asks.
