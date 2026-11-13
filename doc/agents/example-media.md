# Example media

Moved out of AGENTS.md.

| `example/lib/gallery.dart` | Storybook-style gallery of plain and liquid glass over an animated background, for checking the look per platform: `cd example && flutter create --platforms=<p> . && flutter run -t lib/gallery.dart -d <device>` (then revert `.metadata`, `analysis_options.yaml`, `pubspec.lock`). Not covered by tests. |
| `example/lib/showcase.dart` | Hands-free 12 s looping liquid glass scene for screen recordings (`flutter run -t lib/showcase.dart`). Not covered by tests. |
| `example/lib/screens.dart` | Realistic app screens (travel, photos, music, weather) used for the pub.dev screenshots: `flutter run -t lib/screens.dart --dart-define=SCREEN=<name>` on an iPhone simulator. Photos load from picsum.photos (Unsplash License); `photoCredits` lists the authors. Not covered by tests. |
| `example/screenshots/` | Old screenshots. The READMEs of releases up to 2.3.0 still load them by URL from `main`, so don't rename or delete them. |
| `doc/screenshots/` | Current screenshots (made with `example/lib/screens.dart`). They're published with the package and used by the `screenshots:` gallery in `pubspec.yaml`, and `README.md` loads them by URL from `main`. Don't rename them. Keep each one under 4 MB (pub.dev's limit). |
| `doc/readme/` | README-only media, excluded from the package by `.pubignore`. `showcase.webp` is an animated WebP (GIF was 18-25 MB) cut from a macOS `--release` recording of `example/lib/showcase.dart`: frames with `ffmpeg`, then `img2webp -lossy -q 70 -m 6 -d 40` (Homebrew `webp`). `README.md` loads it by URL from `main`, so don't rename it. |
| `doc/api/` | Not tracked. Generated dartdoc output (`dart doc`) is gitignored and in `.pubignore`. Don't commit it. |
