---
name: release
description: Prepare a chord_pro release - pick the version, turn Unreleased into a CHANGELOG section, bump pubspec.yaml, dry-run the publish and open the release PR, then hand the tag and pub.dev publish to the maintainer. Use when the user says release, cut a version, or publish.
---

# Release

Releases are manual; there is no publish workflow. Claude prepares the
release, and the maintainer creates the tag and publishes.

## 1. Pick the version

Read `## Unreleased` in `CHANGELOG.md`.

- Pre-1.0 (current): anything under `### Breaking` bumps the minor
  (`0.8.0` → `0.9.0`); otherwise bump the patch.
- From 1.0 on: semver as usual.

State the version and the reason; the maintainer may overrule.

## 2. Prepare the release PR

On a branch from an up-to-date `main`:

1. Set `version:` in `pubspec.yaml`.
2. Rename `## Unreleased` to `## X.Y.Z`. No date on the heading. Add a
   short lead paragraph summarising the release if it has a theme.
3. Check every entry links its issue and the spec page where one applies,
   and every breaking entry says how to migrate.
4. Run the full gate and tests (the `ship` skill, steps 2–3).
5. `dart pub publish --dry-run` must report 0 warnings. Check the file list
   leaves out `docs/`, `.claude/` and `coverage/`.
6. Commit as `chore(release): X.Y.Z`, push, open the PR against `main`.

## 3. Hand over

After the PR merges and CI on `main` is green, give the maintainer:

- the release link, which creates the tag on publish:
  `https://github.com/ryzizub/chord_pro/releases/new?tag=vX.Y.Z&target=main`
- the release notes: the CHANGELOG section, ending with
  `**Full changelog:** https://github.com/ryzizub/chord_pro/blob/main/CHANGELOG.md`
- the reminder to run `dart pub publish` with their own credentials.

Claude sessions cannot push tags or create releases here, and must never
run `dart pub publish` without `--dry-run`.
