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
- Use short, imperative commit messages. Conventional prefixes are welcome (`feat:`, `fix:`,
  `chore:`, `docs:`, `test:`, `refactor:`). Example: `fix: replace deprecated withOpacity`.
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
| `doc/api/` | **Generated** dartdoc output that is checked in. Don't hand-edit it. Regenerate it with `dart doc` or remove it (see `tasks.md`). |
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
$F test                         # root package tests (none exist yet, see tasks.md)
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
- Every public member gets a `///` dartdoc comment that describes each parameter and its default,
  in the style of the existing `asGlass` doc comment.
- Keep the SDK constraints in `pubspec.yaml` honest. If you use an API such as `Color.withValues`
  (Flutter 3.27+), raise the lower bounds to match. Raising the lower bound is a compatibility
  decision, so mention it in the changelog.
- Before release, aim for a high pub.dev score: `$F pub publish --dry-run` with no warnings, an
  example present, documented API, and up-to-date dependencies.

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
- Use `find.byType` and `tester.widget<T>()` to inspect properties. Consider golden tests for the
  visual output, but keep them deterministic and run them on a single platform.
- The example app's test must test the example app. See `tasks.md`: it's currently the stock
  counter template and fails.
- Run `analyze` and `test` for **both** the root package and `example/` before committing.

### Example app
- `example/` is the package's showcase on pub.dev. Keep it minimal, idiomatic, warning-free, and
  in step with the current API.
- Platform folders (`android/`, `ios/`, `web/`, `windows/`) are gitignored. Don't commit
  generated platform code unless the human asks.

---

## 5. Definition of done (per change)
1. `$F analyze` is clean in the root and in `example/`.
2. `$F test` passes in the root and in `example/`.
3. `dart format` is applied.
4. Public API changes have dartdoc, a `CHANGELOG.md` entry, and a `pubspec.yaml` version bump.
5. `README.md` is updated if usage changed.
6. `tasks.md` (and `AGENTS.md` if applicable) is updated and **everything is committed**.
