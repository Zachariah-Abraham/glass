# tasks.md

Living status of work on this repo. **Update it whenever you make progress** (see AGENTS.md §1).
Newest information goes first in each section. Use absolute dates.

_Last updated: 2026-11-03_

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
- Test automation (branch `test/goldens-and-example-build`): built-in golden tests (7 scenes,
  pinned-Flutter CI job) and an example web-build job are written. Not yet verified on Linux CI:
  the references were generated on macOS. If CI reports pixel diffs, regenerate on Linux. Still to
  do: a web/Linux `integration_test` smoke test, and a manually triggered Android emulator test for
  issue #7 (decided: slow and flaky tests stay local or `workflow_dispatch`, not on every PR).
- Renaming the misspelled public parameter `clipBehaviour` to `clipBehavior` (human decision,
  2026-11-06). Step 1 (PR on `feat/clip-behavior`): add `clipBehavior`, keep `clipBehaviour` as a
  `@Deprecated` alias, ships as a minor (2.2.0). Step 2 (later, next major 3.0.0): delete
  `clipBehaviour`, with a `feat!:` commit or `BREAKING CHANGE:` footer. Other 3.0.0 candidates: none
  decided yet.

## Backlog (suggested, not yet approved by the human)
- [ ] Issue #7 (blur disappears at scroll limits): likely Android stretch overscroll, whose
      `ImageFilter` layer hides the backdrop. Not reproduced on a device yet. Plan: README "Known
      limitations" with workarounds, an example, a regression test, then reply and close.
- [ ] Apple "liquid glass" support (needs scoping: refraction needs a fragment shader).
- [ ] Optional hardening of automated publishing: GitHub tag protection rules for `v*`, and a
      required `pub.dev` environment (AGENTS.md §6).

## Done
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
