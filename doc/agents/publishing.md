# Publishing to pub.dev

Moved out of AGENTS.md. Agents never publish; the human merges the release PR.

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
   - Keep the `# Changelog` title on the first line of `CHANGELOG.md`; release-please inserts new
     entries right after it. PRs are squash-merged with the PR title as the commit subject, so the
     PR title is the changelog entry: give PRs user-facing Conventional Commit titles.
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
  `example/screenshots/`, `doc/readme/` and `doc/agents/`. The archive is ~3 MB, almost all of it the
  `doc/screenshots/` pub.dev gallery, which must be published. **Keep the two files in sync** when adding
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
Hardening (set up 2026-11-09):
- GitHub ruleset "Protect release tags" (repo Settings → Rules): only repo admins may create, move or
  delete `v*` tags. release-please creates tags with `RELEASE_PLEASE_TOKEN`, a PAT of the repo owner
  (an admin), so it is allowed. If that token ever becomes a GitHub App or a non-admin's PAT, add it
  as a bypass actor or releases will fail to tag.
- `publish.yml` runs in the GitHub environment `pub.dev`, which only `v*` tags may deploy to. On
  pub.dev (package Admin tab), "Require GitHub Actions environment" is set to `pub.dev`, so a
  workflow outside that environment can't publish. (Only the human can change pub.dev settings;
  `tasks.md` says whether this one is on yet.)

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
