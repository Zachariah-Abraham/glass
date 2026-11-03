# tasks.md

Living status of work on this repo. **Update it whenever you make progress** (see AGENTS.md §1).
Newest information goes first in each section. Use absolute dates.

_Last updated: 2026-10-29_

## Current state
- Package version `2.0.0+2` (`pubspec.yaml`). Last code change: "chore: Address lints".
- With Flutter 3.47.7 / Dart 3.13.5 (FVM `stable`):
  - Root `flutter analyze`: **2 infos**, both `withOpacity` deprecations at
    `lib/src/glass_widget.dart:49-50`.
  - `example/` analyze: clean.
  - `example/` test: **fails**. `example/test/widget_test.dart` is the stock counter template.
  - The root package has **no tests** and **no `analysis_options.yaml`**.

## In progress
- _(none)_

## Backlog (suggested, not yet approved by the human)
- [ ] Add root `analysis_options.yaml` (`include: package:flutter_lints/flutter.yaml`) and add
      `flutter_lints` to the root dev_dependencies. Then fix the new lints (for example the
      `new ImageFilter.blur` keyword).
- [ ] Replace `tintColor.withOpacity(x)` with `withValues(alpha: x)`. This needs Flutter >= 3.27
      (human approved raising the minimum). Raise the `environment` constraints in `pubspec.yaml`,
      note it in `CHANGELOG.md`; this is not an API change, so a minor bump (2.1.0) fits.
- [ ] Add root `test/glass_widget_test.dart` with widget tests for each parameter
      (see AGENTS.md §4 Testing).
- [ ] Replace `example/test/widget_test.dart` with a real smoke test (renders "Night sky", and
      tapping toggles `enabled`, which removes or adds the `BackdropFilter`).
- [ ] Clean up the example: remove the no-op `GestureDetector` around `TextButton`, give the
      pubspec a real description, and use single quotes or consistent style.
- [ ] Regenerate `doc/api/` with `dart doc` before the next release (kept on purpose, see Decisions).
- [ ] Update `README.md`: replace `pub get` with `flutter pub add glass`, and document every
      `asGlass` parameter.
- [ ] Run `flutter pub publish --dry-run` and fix any warnings.

## Done
- 2026-11-03: `RELEASE_PLEASE_TOKEN` Actions secret added; `ci/release-please` merged and pushed to `main`. Release automation is live: the next `feat:`/`fix:` commit on `main` opens a release PR.
- 2026-11-03: Pushed `main`; pub.dev automated publishing enabled by the human. Added release-please (branch `ci/release-please`, not merged: needs `RELEASE_PLEASE_TOKEN`).
- 2026-11-03: Merged `docs/agent-guidelines` into local `main`; added `.github/workflows/publish.yml` (tag-triggered pub.dev publish).
- 2026-10-29: Added publishing guide (AGENTS.md §6).
- 2026-10-29: Added `AGENTS.md`, `CLAUDE.md`, and `tasks.md` (agent onboarding and hand-off docs).

## Decisions made
- 2026-10-29: Raising the minimum Flutter version for `withValues` is OK.
- 2026-11-03: Keep the checked-in `doc/api/` (human decision). Regenerate rather than delete.

## Open questions for the human
- Enable automated publishing on pub.dev (see Backlog / AGENTS.md §6) and push `main`.
