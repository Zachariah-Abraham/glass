# Testing and tooling details

Moved out of AGENTS.md. Short rules stay there; this has the procedures.

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
- **Liquid shader tests** (`test/liquid_shader_test.dart`, `test/liquid_precache_test.dart`) only run
  with `$F test --enable-impeller` (shader image filters need Impeller) and are skipped otherwise.
  `test/liquid_precache_test.dart` is a separate file because the loaded shader is cached per test
  isolate. `test/typical_widgets_test.dart` wraps 25 everyday widgets (plain and liquid) and checks
  that size, semantics, taps, typing and scrolling don't change; it runs both ways. The
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
- **Android emulator speed:** the local AVD `Medium_Phone_API_37.0` with `hw.gpu.mode=auto` resolves to
  `lavapipe` (software rendering on the host CPU, 1 core) and runs the gallery at ~1-4 fps. Start it with
  `~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_37.0 -gpu host -cores 4` for GPU rendering.
  Emulator frame rates are still only a rough guide; check performance on a real device.
- **Recording demos:** the iOS simulator only runs debug builds, and its screen recordings stutter
  (many frames > 50 ms apart). For smooth videos, record a `--release` build on a real device or on
  macOS desktop.
