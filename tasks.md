# tasks.md

Current state and pending work only. **Keep it short:** when something is done, delete it (the
commit history and `CHANGELOG.md` are the record); move lasting facts to `AGENTS.md`. Use absolute
dates. See AGENTS.md §1.

_Last updated: 2026-11-07_

## Current state
- **glass 2.3.0** (experimental liquid glass, minimum Flutter 3.29 / Dart 3.7) was released on
  2026-11-07: release PR #17 merged, tag `v2.3.0`, and `publish.yml` uploaded it ("Successfully uploaded
  ... version 2.3.0"). Releases are automated (AGENTS.md §6).
- Root and `example/` analyze clean and tests pass on Flutter 3.47.7 (FVM `stable`), with and without
  `--enable-impeller`.

## In progress
- Showcase recording for the merged liquid glass PR #16 and a LinkedIn post: **the human records it.**
  The scene is `example/lib/showcase.dart` (PR #18, open for review). Run it with
  `cd example && flutter run -t lib/showcase.dart -d <device>`.

- pub.dev screenshots and metadata (PR #19, stacked on PR #18): `pubspec.yaml`
  has a `screenshots:` gallery (in this order: weather, music, travel, photos; images are in `doc/screenshots/`,
  made with `example/lib/screens.dart`), the `liquid-glass` topic (it replaces `widget`), and a new
  `description`. They reach pub.dev with the next release (a `fix:` commit, so 2.3.1). `README.md` now shows
  weather and music from `doc/screenshots/` (by URL from `main`, so they appear on GitHub after the merge).

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
