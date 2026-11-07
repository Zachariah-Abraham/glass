# AGENTS.md

Guide for AI coding agents (and humans) working on this repository. Read this file and
[`tasks.md`](tasks.md) before starting any work.

---

## 1. Working agreement (read first)

### Commit your work
- **Always commit your work.** Make small, focused commits as you go. Don't leave a large
  uncommitted diff at the end of a session.
- Each commit should leave the repo in a working state: `flutter analyze` is clean and tests
  pass. If you have to commit something broken, say so in the commit message and in `tasks.md`.
- Use [Conventional Commits](https://www.conventionalcommits.org) (**required**: release automation
  derives version bumps and the changelog from them, see §6). Types: `feat:` (minor), `fix:`
  (patch), `feat!:` or a `BREAKING CHANGE:` footer (major), and `docs:`, `chore:`, `ci:`, `test:`,
  `refactor:`, `perf:` (no release). Example: `fix: replace deprecated withOpacity`.
- Work on `main` only if the human asks you to. Otherwise use a feature branch. Never force-push,
  rewrite published history, or run `dart pub publish` without explicit human approval.

### Treat all work as hand-off-able
Assume that **at any moment** your context may be auto-compacted, your session may end, or
another agent may pick up where you left off. The human should be able to learn the current
state by reading the docs alone. So:

1. **Update [`tasks.md`](tasks.md) whenever you make progress**: when you start a task, finish
   one, find a new problem, or change plans. Record what's done, what's in progress (and how far
   along it is), what's next, and any blockers or open questions.
2. **Update this file (`AGENTS.md`)** if you learn something every future agent needs: a new
   command, a tooling quirk, a convention, or an architecture change. Keep it accurate. Delete
   stale information instead of piling notes on top of it.
3. Commit `tasks.md` and `AGENTS.md` updates **together with the work they describe** (or right
   after it), not at the end of the session.
4. Write notes for a reader with no context. Name files, functions, commands, and decisions
   explicitly. Avoid phrases like "as discussed" or "the earlier fix".

---

## 2. Project overview

**`glass`** is a small, published Flutter **package** on [pub.dev](https://pub.dev/packages/glass)
(repo: `github.com/Zachariah-Abraham/glass`, BSD-3-Clause). It turns any widget into a
"glass" / frosted-glass (glassmorphism) version of itself through one extension method:

```dart
import 'package:glass/glass.dart';

Container(child: someChild).asGlass(
  blurX: 10, blurY: 10,
  tintColor: Colors.white,
  frosted: true,
  clipBorderRadius: BorderRadius.circular(15),
);
```

This is a **library that other people depend on**, not an app. Public API stability, semver,
documentation, and the changelog matter more than they would in an app.

### Layout

| Path | Purpose |
|---|---|
| `lib/glass.dart` | Public library entry point. Only exports `src/`. |
| `lib/src/glass_widget.dart` | The whole implementation: `extension GlassWidget<T extends Widget> on T` with `asGlass(...)`. |
| `images/noise.png` | Noise texture for the "frosted" look. Declared as a package asset in `pubspec.yaml` and loaded with `AssetImage('images/noise.png', package: 'glass')`. |
| `example/` | Demo app (`example/lib/main.dart`) that depends on the package through `path: ../`. Shown on pub.dev. |
| `example/screenshots/` | Screenshots referenced by URL from `README.md`. Don't rename them. |
| `doc/api/` | Not tracked. Generated dartdoc output (`dart doc`) is gitignored and in `.pubignore`; the human removed the old checked-in copy on 2026-11-03. Don't commit it. |
| `CHANGELOG.md` | Displayed on pub.dev. Update it for every user-visible change. |

### How `asGlass` works
`asGlass()` returns `this` unchanged when `enabled == false`. Otherwise it builds:

```
ClipRRect(borderRadius / clipper, clipBehavior)
 └─ BackdropFilter(ImageFilter.blur(sigmaX: blurX, sigmaY: blurY, tileMode))
     └─ Container(BoxDecoration(
          gradient: tint (opacity 0.10 → 0.08, topLeft → bottomRight), omitted if tintColor == Colors.transparent
          image: noise.png (BoxFit.cover), omitted if frosted == false))
         └─ this (the original widget)
```

Things to keep in mind:
- `BackdropFilter` blurs what is **behind** the widget. The effect only shows up when there is
  content underneath, for example in a `Stack` or over a background image.
- `BackdropFilter` is relatively expensive. Avoid patterns that stack many of them or rebuild
  them every frame.
- The return type is `Widget`. 2.0.0 made this a breaking change from `ClipRRect`. Changing the
  public signature or defaults requires a **major** version bump.

---

## 3. Tooling and commands

Flutter is managed with **FVM**. `flutter` and `dart` are shell aliases for `fvm flutter` and
`fvm dart`, but **no version is pinned** for this project (`.fvmrc` is gitignored) and there's no
global FVM version, so `fvm flutter` fails in non-interactive shells. Call the cached SDK
directly:

```bash
F=~/fvm/versions/stable/bin/flutter   # Flutter 3.47.x / Dart 3.13.x as of 2026-10-29

$F pub get                      # root package
$F analyze                      # root package (must be clean before committing)
$F test --exclude-tags golden   # root package tests, without pixel goldens (see "Golden tests")
(cd example && $F analyze && $F test)
dart format .                   # or: ~/fvm/versions/stable/bin/dart format .
$F pub publish --dry-run        # validates the package; NEVER run without --dry-run unless the human asks
```

**Tooling side effects:** `pub get` and `analyze` on a newer SDK rewrite `pubspec.lock` and
`example/pubspec.lock`, and may add excludes to `example/analysis_options.yaml`. Don't commit
those incidental changes as part of unrelated work. Either revert them
(`git checkout -- <file>`) or commit them on purpose in their own commit.

---

## 4. Flutter / Dart best practices for this repo

### Package and API design
- Keep the public surface small. Export only from `lib/glass.dart`. Implementation lives in
  `lib/src/`, and other packages must never need to import `src/`.
- Follow [semver](https://dart.dev/tools/pub/versioning): a breaking change means a major bump,
  a new feature means a minor bump, and a fix means a patch. Bump `version` in `pubspec.yaml` and
  add a `CHANGELOG.md` entry in the same change. Match the existing changelog format:
  `## [x.y.z] - YYYY-MM-DD` followed by bullets.
- New parameters must be optional and keep today's defaults, so existing users see identical
  rendering.
- When imitating a platform look (for example Apple's liquid glass), model the *effect*, but keep
  platform defaults such as corner shape and borders under the caller's control, even if that
  changes the result. Platform-specific shapes (for example continuous corners) are opt-in.
- Every public member gets a `///` dartdoc comment that describes each parameter and its default,
  in the style of the existing `asGlass` doc comment.
- Keep the SDK constraints in `pubspec.yaml` honest. If you use an API such as `Color.withValues`
  (Flutter 3.27+), raise the lower bounds to match. Raising the lower bound is a compatibility
  decision, so mention it in the changelog.
- Before release, aim for a high pub.dev score: `$F pub publish --dry-run` with no warnings, an
  example present, documented API, and up-to-date dependencies. See §6 for the full process.

### Dart style
- Follow [Effective Dart](https://dart.dev/effective-dart). Format with `dart format` (default
  page width).
- Lint with `flutter_lints` (or the stricter `lints/recommended`). Fix analyzer warnings instead
  of suppressing them. If an `// ignore:` is truly necessary, add a reason next to it.
- Use sound null safety. Avoid `!` unless an invariant guarantees the value.
- Don't use the `new` keyword. Prefer `final` for locals that aren't reassigned and `const`
  constructors and literals wherever possible.
- Replace deprecated APIs instead of ignoring them (for example `withOpacity` → `withValues(alpha:)`).
- Use `lowerCamelCase` for members, `UpperCamelCase` for types, and `snake_case.dart` for files.

### Widgets and performance
- Prefer composing small widgets over helper methods that return widgets (in app/example code).
- Use `const` widgets so subtrees don't rebuild needlessly.
- Avoid unnecessary layers. For example, don't wrap a `TextButton` in a no-op `GestureDetector`.
- Keep `build()` pure and cheap: no I/O and no heavy allocation.
- Be careful with `BackdropFilter`, `saveLayer`, and clipping. Prefer `Clip.antiAlias` over
  `Clip.antiAliasWithSaveLayer` unless you need the latter.
- Don't hard-code colors or sizes that should come from the caller. Expose a parameter with a
  sensible default instead.

### Accessibility
- The glass effect is purely visual and must not change the child's semantics.
- Example UIs should have enough contrast for text on glass and work with large text scales.

### Testing
- Every behavior change to `asGlass` needs **widget tests** in a root `test/` directory using
  `flutter_test`. Useful assertions:
  - `enabled: false` returns the original widget, with no `ClipRRect` or `BackdropFilter`.
  - Blur sigma, tile mode, clip behavior, border radius, and clipper reach the right widgets.
  - `tintColor: Colors.transparent` produces no gradient. `frosted: false` produces no image.
  - The noise asset resolves (`package: 'glass'`).
- Use `find.byType` and `tester.widget<T>()` to inspect properties.
- The minimum is Flutter 3.29 / Dart 3.7 because the liquid path uses `ImageFilter.shader`
  (not in 3.27's `dart:ui`; 3.28 was never a stable release). Dart 3.7 language versions use the
  "tall" `dart format` style.
- To run tests on another Flutter version, install it (`fvm install 3.29.0`, then
  `~/fvm/versions/3.29.0/bin/flutter`). When switching versions, `rm -rf build/unit_test_assets`
  first: the compiled shader there is version-specific and isn't always rebuilt ("Runtime stages
  buffer failed verification"). Afterwards revert the lockfile and `example/` changes `pub get` makes.
- **Liquid shader tests** (`test/liquid_shader_test.dart`) only run with
  `$F test --enable-impeller` (shader image filters need Impeller) and are skipped otherwise. The
  liquid group in `test/glass_widget_test.dart` tests the plain blur fallback and is skipped under
  Impeller. Run the suite both ways when you touch the liquid path.
- **Golden tests** (`test/glass_golden_test.dart`, tag `golden`, images in `test/goldens/`) render
  `asGlass` variants over a striped background and compare pixels with Flutter's built-in
  `matchesGoldenFile`. Rules:
  - Pixel output depends on the Flutter version, so CI runs them only in the `golden` job, pinned
    to `GOLDEN_FLUTTER_VERSION` in `.github/workflows/ci.yml`. The version matrix runs
    `flutter test --exclude-tags golden`. Use the same locally unless you're on the pinned version.
  - Scenes contain no text, so results don't depend on fonts. Keep it that way, and keep them
    deterministic (fixed size, device pixel ratio 1, no animation).
  - Regenerate with `$F test --update-goldens --tags golden` using the pinned version, whenever
    the look changes on purpose or the pinned version is bumped.
  - **Generate references on Linux, not macOS.** macOS output differs by a few pixels, so CI fails
    on macOS-made references. Push the change, let the `golden` job fail, download its
    `golden-failures` artifact (`gh run download <id> -n golden-failures`) and copy each
    `<name>_testImage.png` to `test/goldens/<name>.png`.
  - Some differences are subtle by design (noise is at most ~9/255, a 10% tint ~26/255). The tests
    are pixel-exact, so they still catch regressions even when you can't see the difference.
  - **Always open the changed PNGs and look at them before committing.** An empty or wrong scene
    still "passes" once its blank image is the reference.
  - Goldens are excluded from the published package (`.pubignore`).
- CI also builds the example app for web against the package (`example-build` job).
- `example/integration_test/app_test.dart` is a smoke test on a real engine (not the widget-test
  binding). CI runs it on Linux desktop under xvfb (`integration` job); locally run
  `flutter create --platforms=macos . && flutter test integration_test -d macos` in `example/`, then
  revert the incidental changes to tracked files (`example/macos/`, `pubspec.lock`, etc.).
- Run `analyze` and `test` for **both** the root package and `example/` before committing.

### Example app
- `example/` is the package's showcase on pub.dev. Keep it minimal, idiomatic, warning-free, and
  in step with the current API.
- Platform folders (`android/`, `ios/`, `web/`, `windows/`) are gitignored. Don't commit
  generated platform code unless the human asks.

---

## 5. Definition of done (per change)
CI (`.github/workflows/ci.yml`) runs on pushes to `main` and on PRs: analyze and tests (excluding
goldens) for the root and `example/` on Flutter 3.29.0 (the minimum) and latest stable, plus a
format check and `flutter pub publish --dry-run` on stable. Separate jobs run the golden tests on a
pinned Flutter version and build the example for web. Dev dependencies must resolve on the minimum SDK, which
is why `flutter_lints` is `^5` (v6 needs Dart 3.8).

1. `$F analyze` is clean in the root and in `example/`.
2. `$F test` passes in the root and in `example/`.
3. `dart format` is applied.
4. Public API changes have dartdoc, a `CHANGELOG.md` entry, and a `pubspec.yaml` version bump.
5. `README.md` is updated if usage changed.
6. `tasks.md` (and `AGENTS.md` if applicable) is updated and **everything is committed**.

---

## 6. Publishing to pub.dev

**Agents never publish.** Publishing is permanent: pub.dev generally doesn't allow unpublishing,
so only the human runs the real `pub publish` (or pushes the release tag). Agents prepare the
release and run `--dry-run`.

### Release checklist
Releases are automated with [release-please](https://github.com/googleapis/release-please-action)
(`.github/workflows/release-please.yml`, config in `release-please-config.json`, last released
version in `.release-please-manifest.json`):
1. Merge changes to `main` using Conventional Commits (§1). `feat` → minor, `fix` → patch,
   `!`/`BREAKING CHANGE` → major.
2. release-please keeps a "release PR" open that bumps `version:` in `pubspec.yaml` and prepends
   to `CHANGELOG.md`. **Don't hand-edit `version:` or add changelog entries for releases**, and
   don't edit the manifest. Merging the release PR is the human's decision.
3. Merging the release PR creates the `vX.Y.Z` tag, which triggers `publish.yml`, which publishes
   to pub.dev.
4. Before the human merges the release PR, make sure of the following (agents can check these
   and report in `tasks.md`):
   - §5 passes on `main`. `$F pub publish --dry-run` shows no warnings. Read its file list.
   - `LICENSE`, `README.md` (main pub.dev page) and `pubspec.yaml` (`description` 60-180 chars,
     `homepage`/`repository`, optionally `issue_tracker` and `topics`) are accurate.
   - Anything users must know (for example a raised minimum SDK) appears in the changelog. Only
     commit **subjects** reach `CHANGELOG.md`; bodies do not. Put the note in a `feat:`/`fix:`
     subject (for example `feat: require Flutter 3.29 or newer`) or add a `BREAKING CHANGE:`
     footer, which release-please prints. Hand-edits to the release PR's changelog are overwritten
     the next time it regenerates.
   - Raising the minimum SDK is **not** a breaking change (pub resolves users on older SDKs to the
     older release), so it is a `feat`/`fix`, not a major bump.
- The release PR needs the repo secret `RELEASE_PLEASE_TOKEN` (a PAT or GitHub App token).
  `GITHUB_TOKEN` can't be used because tags it creates don't trigger `publish.yml`.
- Fallback (manual): bump `version:`, edit `CHANGELOG.md`, then `git tag vX.Y.Z && git push
  origin vX.Y.Z`. Agents don't push release tags.

### What gets uploaded
- Everything under the package root except hidden files/dirs (names starting with `.`) and
  anything matched by `.gitignore` or `.pubignore`. A `.pubignore` in a directory overrides that
  directory's `.gitignore` for publishing only.
- Keep the package small (limit is ~100 MB gzipped / 256 MB uncompressed). Large demo assets and
  generated output should be excluded. A root `.pubignore` exists, and pub then **ignores
  `.gitignore`** for publishing, so `.pubignore` is a copy of `.gitignore` plus
  `example/screenshots/` (archive ~3 MB → ~750 KB). **Keep the two files in sync** when adding
  ignore rules.
- Only hosted pub.dev dependencies and SDK dependencies (`sdk: flutter`) are allowed. `path:`
  and `git:` dependencies are not (the `example/` app is fine because it isn't published).

### Docs
- pub.dev **generates and hosts API docs itself** from `///` comments, and IDEs read the `///`
  comments directly from source. Local `dart doc` output (`doc/api/`) is gitignored and not
  published, so there's nothing to regenerate or commit.
- The package page is built from `README.md`, `CHANGELOG.md`, `pubspec.yaml`, and `example/`.
  README images need absolute URLs (as now).

### SDK constraints and old versions
- pub's solver picks, for each user, the newest version whose SDK constraint admits the user's
  SDK. So raising the minimum Flutter/Dart version in a new release doesn't break users on older
  SDKs: they simply keep resolving to the older release. Users can also pin an exact old version
  (`glass: 2.0.0+2`). Published versions stay on pub.dev.
- Still mention the new minimum SDK in the changelog.

### Mistakes after publishing
- Versions can't be deleted. Prefer publishing a fixed patch version with a changelog note.
- **Retract** (pub.dev package Admin tab) only within 7 days of publishing, and when a version is
  truly broken (for example wrong dependency constraints). Retraction is reversible within
  7 days.
- Use **discontinued** for packages that are no longer maintained.

### Automated publishing (enabled on pub.dev)
`.github/workflows/publish.yml` publishes to pub.dev from GitHub Actions using OIDC (no stored
secrets) when a tag matching `v[0-9]+.[0-9]+.[0-9]+` is pushed (normally by release-please).
pub.dev is configured for repo `Zachariah-Abraham/glass` with tag pattern `v{{version}}`. The tag
must equal `v` + `version:` in `pubspec.yaml`, so use plain `x.y.z` (no `+N` build suffix).
Optional hardening: GitHub tag protection rules, and a required `pub.dev` environment (enable on
pub.dev, create the same environment on GitHub, uncomment the `with: environment` lines).

### Links
- Publishing: https://dart.dev/tools/pub/publishing
- Versioning: https://dart.dev/tools/pub/versioning
- Pubspec reference: https://dart.dev/tools/pub/pubspec
- Package layout: https://dart.dev/tools/pub/package-layout
- Automated publishing: https://dart.dev/tools/pub/automated-publishing
- Writing package pages: https://dart.dev/tools/pub/writing-package-pages
- Verified publishers: https://dart.dev/tools/pub/verified-publishers
- Package scoring (pub points): https://pub.dev/help/scoring
- Effective Dart: https://dart.dev/effective-dart
- Developing packages (Flutter): https://docs.flutter.dev/packages-and-plugins/developing-packages
