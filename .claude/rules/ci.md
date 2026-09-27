---
paths:
  - ".github/**"
  - "pubspec.yaml"
  - "analysis_options.yaml"
---

# CI, SDK and lint bumps

- `.github/workflows/ci.yaml` calls the Very Good Ventures reusable
  workflows (`VeryGoodOpenSource/very_good_workflows`, pinned to a major
  tag): `semantic_pull_request.yml` for the PR title, `dart_package.yml` for
  format, analyze (`--fatal-infos --fatal-warnings`), tests with
  randomized ordering and the coverage gate, and `license_check.yml`.
- The coverage gate is `min_coverage: 85`. Don't lower it; raise it when
  coverage allows.
- `run_bloc_lint: false`: there is no bloc here.
- PR titles use the Conventional Commit types and scopes listed in
  CLAUDE.md; keep the `scopes` input in `ci.yaml` in sync with that list.
- SDK bumps use the `dart-flutter-sdk-upgrade` skill, lint bumps the
  `very-good-analysis-upgrade` skill. Raising the `environment: sdk` floor
  drops users on older SDKs, so it needs a reason beyond syntax and a
  CHANGELOG entry.
- `very_good_analysis` is a range (`>=7.0.0 <12.0.0`) so the package still
  resolves on the SDK floor. Widen the upper bound on a new major; don't
  raise the lower bound without raising the SDK floor.
- `analysis_options.yaml` overrides a lint only with a comment explaining
  why, as the existing `avoid_equals_and_hash_code_on_mutable_classes` entry
  does.
- Dependabot keeps pub and GitHub Actions versions current; review its PRs
  like any other.
