---
name: ship
description: Run chord_pro's full CI gate and test suite, commit, push the branch and open a pull request against main. Use when the user says ship it, open a PR, push this, or when finishing a /build.
---

# Ship

Takes a finished change on a branch to an open pull request, green locally.

## 1. Check the branch

- Never ship from `main`. If on `main`, create a branch first
  (`<type>/<short-slug>`, or the session's assigned `claude/…` branch).
- `git status` must show only changes that belong to this PR. Leave
  unrelated files out and say so.

## 2. Run the gate over the whole repo

```bash
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings lib test example
```

Fix every finding, including infos, then re-run. Run `dart format .` to fix
formatting rather than editing whitespace by hand.

## 3. Run the full suite with coverage

very-good-cli MCP `test` tool: `dart: true`, `coverage: true`,
`min_coverage: 85`. If the MCP server is not running, use the command CI
runs:

```bash
very_good dart test --coverage --min-coverage 85 --test-randomize-ordering-seed random
```

A red `spec_audit_test.dart` test is an audit finding, not a flake: fix
the parser or record the gap per `.claude/rules/spec-audit.md`.

## 4. Check the definition of done

Go through the list in CLAUDE.md. In particular:

- ledgers: new directive names in the checklist or
  `doc/reference/non-spec-extensions.md`; new public types in
  `lib/chord_pro.dart`;
- `CHANGELOG.md` has an entry under `## Unreleased` for any user-visible
  change (create the heading above the latest version if missing);
- a changed architecture decision has an ADR in `docs/adr/`;
- `dart run example/chord_pro_example.dart` still runs if the public API
  changed.

## 5. Commit and push

- Conventional Commit with a scope from CLAUDE.md; subject in the
  imperative, describing what a package user sees. `!` after the scope for
  a breaking change, plus a `BREAKING CHANGE:` footer.
- Commit brainstorm and plan files from `docs/` that led to this change.
- `git push -u origin <branch>`.

## 6. Open the pull request

- Title: the same Conventional Commit format (CI checks it).
- Body: fill `.github/PULL_REQUEST_TEMPLATE.md` (Description, Type of
  Change). Link the issue and the spec page.
- Target `main`. Use the GitHub MCP tools or `gh`, whichever the session
  has.
- Report the PR link only after steps 2 and 3 were green.
