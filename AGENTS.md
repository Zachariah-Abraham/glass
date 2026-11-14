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
   one, find a new problem, or change plans. It holds only the current state, what's in progress
   (and how far along it is), pending work, blockers and open questions. **Delete finished items**
   instead of keeping a history (git and `CHANGELOG.md` are the record), and move facts every future
   agent needs into this file.
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
| `shaders/liquid_glass.frag` | Fragment shader for liquid glass (refraction, saturation, tint, lift, rim). Declared under `flutter: shaders:` in `pubspec.yaml`. |
| `images/noise.png` | Noise texture for the "frosted" look. Declared as a package asset in `pubspec.yaml` and loaded with `AssetImage('images/noise.png', package: 'glass')`. |
| `example/` | Demo app (`example/lib/main.dart`) that depends on the package through `path: ../`. Shown on pub.dev. |
| `example/lib/gallery.dart`, `showcase.dart`, `screens.dart` | Manual-check apps (platform gallery, looping recording scene, pub.dev screenshots). Not tested. Run commands: [`doc/agents/example-media.md`](doc/agents/example-media.md). |
| `example/screenshots/`, `doc/screenshots/`, `doc/readme/` | Screenshots and README media loaded by URL from `main`: **don't rename or delete them**. `doc/screenshots/*` are published (each < 4 MB). Details in `doc/agents/example-media.md`. |
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

### Liquid glass (`asGlass(liquid: LiquidGlass...)`, experimental)
- `LiquidGlass.clear` / `.regular` are presets fitted to native iOS 26 glass. Explicit `blurX`, `blurY`,
  `tintColor`, `frosted` override the preset. `liquid: null` (default) renders exactly as plain glass.
- The shader path needs `ImageFilter.isShaderFilterSupported` (Impeller: iOS, Android, macOS). Web and
  Skia fall back to a plain blur.
- The blur and the shader are separate backdrop filters. **Never compose or nest them** (3x slower, and
  the shader's coordinates break). Uniforms are recomputed before every push. Details, the native
  refraction model and `grouped:` internals: [`doc/agents/liquid-glass.md`](doc/agents/liquid-glass.md).

---

## 3. Tooling and commands

Flutter is managed with **FVM**. `flutter` and `dart` are shell aliases for `fvm flutter` and
`fvm dart`, but **no version is pinned** for this project (`.fvmrc` is gitignored) and there's no
global FVM version, so `fvm flutter` fails in non-interactive shells. Call the cached SDK
directly:

```bash
F=~/fvm/versions/stable/bin/flutter   # Flutter 3.50.0 as of 2026-11-13 (`flutter upgrade` updates it)

$F pub get                      # root package
$F analyze                      # root package (must be clean before committing)
$F test --exclude-tags golden   # root package tests, without pixel goldens (see doc/agents/testing.md)
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
- Flutter 3.50 deprecates `package:flutter/material.dart` (and `cupertino.dart`); `flutter analyze`
  on stable then fails with `deprecated_member_use`. The library imports only `widgets.dart` and
  uses private `Color` constants instead of `Colors` (`Color(0xFFFFFFFF)` is `Colors.white`). Tests
  and `example/` still use Material, and `material_ui` doesn't exist on the minimum Flutter 3.29, so
  each such file has `// ignore_for_file: deprecated_member_use` with the reason. Drop those when the
  minimum SDK moves past 3.50.
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
- Every behavior change to `asGlass` needs **widget tests** in `test/` (`flutter_test`).
- Minimum is Flutter 3.29 / Dart 3.7 (`ImageFilter.shader`); CI tests 3.29.0 and stable.
- Liquid shader tests only run with `$F test --enable-impeller`; run the suite both ways when you touch
  the liquid path.
- Golden tests (tag `golden`) are pinned to one Flutter version in CI. **Generate references on Linux
  (from the CI `golden-failures` artifact), not macOS, and open the changed PNGs before committing.**
- Run `analyze` and `test` for **both** the root package and `example/` before committing.
- Procedures (other SDK versions, goldens, integration test, Android emulator, recording demos):
  [`doc/agents/testing.md`](doc/agents/testing.md).

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

**Agents never publish.** Publishing is permanent. Releases are automated with release-please: merge
Conventional Commit PRs to `main`; it keeps a release PR open (bumps `version:`, prepends
`CHANGELOG.md`); the human merges it, which tags `vX.Y.Z` and triggers `publish.yml` (OIDC, in the
`pub.dev` environment). Agents don't hand-edit `version:`, the changelog entries or the manifest, and
don't push tags. PR titles become changelog entries, so make them user-facing. Only `feat`/`fix`
subjects and `BREAKING CHANGE:` footers reach the changelog; raising the minimum SDK is not breaking.
Keep `.pubignore` in sync with `.gitignore` (pub ignores `.gitignore` when `.pubignore` exists).
Run `$F pub publish --dry-run` to check. Full checklist, upload rules, hardening and post-publish
mistakes: [`doc/agents/publishing.md`](doc/agents/publishing.md).
