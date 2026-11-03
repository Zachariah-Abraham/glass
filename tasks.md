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
- _(none)_

## Backlog (suggested, not yet approved by the human)
- [ ] Regenerate `doc/api/` with `dart doc`. It's stale (kept on purpose, see Decisions). Use a
      `docs:` commit so it doesn't cut a release.
- [ ] Optional: exclude big example assets from the published archive via `.pubignore`
      (`example/screenshots/`, `example/images/`; archive is ~3 MB). README images use GitHub
      URLs, so they don't need to ship.
- [ ] Optional hardening of automated publishing: GitHub tag protection rules for `v*`, and a
      required `pub.dev` environment (AGENTS.md §6).
- [ ] Optional: add `topics`, `issue_tracker` and `repository` to `pubspec.yaml` for pub.dev.
- [ ] Optional: CI workflow running `flutter analyze` and `flutter test` on PRs and pushes to
      `main` (none exists yet; release PRs aren't checked either).

## Done
- 2026-11-03: Released 2.1.0 (`withValues`, minimum Flutter 3.27 / Dart 3.6). First end-to-end
  automated release: release PR #9 merged, tag `v2.1.0` published to pub.dev.
- 2026-11-03: Added root `flutter_lints` config, 10 widget tests, a real example test, example
  cleanup, and the README parameters table. Analyze and tests clean.
- 2026-11-03: Added release-please (`release-please.yml`, config and manifest) and the
  tag-triggered `publish.yml`. Dropped the `+N` build suffix from `version:` so tags match
  pub.dev's `v{{version}}`.
- 2026-10-29: Added `AGENTS.md` (incl. the publishing guide in §6), `CLAUDE.md` and `tasks.md`.

## Decisions made
- 2026-11-03: Raising the minimum SDK isn't a breaking change (pub resolves users on older SDKs
  to the older release), so it ships as a minor release. Note it in a commit **subject** so it
  reaches the changelog.
- 2026-11-03: Keep the checked-in `doc/api/` (human decision). Regenerate rather than delete.
- 2026-10-29: Raising the minimum Flutter version for `withValues` is OK.

## Open questions for the human
- Which of the optional backlog items, if any, do you want done?
