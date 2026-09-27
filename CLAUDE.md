# chord_pro

A pure-Dart parser for the [ChordPro 6 song format](https://www.chordpro.org/chordpro/),
published on [pub.dev](https://pub.dev/packages/chord_pro). Zero runtime
dependencies; `test` and `very_good_analysis` are the only dev dependencies,
and that is deliberate (no `package:meta`, no `collection`).

- One package at the repo root. Dart SDK floor is `^3.5.0`; CI builds on
  `stable`. Don't raise the floor for syntax alone: users on older SDKs lose
  the package.
- `main` carries the next release. Branch from it and target PRs at it.
- Hosted on GitHub (`ryzizub/chord_pro`). CI is GitHub Actions on the
  Very Good Ventures reusable workflows.

## Repository layout

- `lib/chord_pro.dart`: the curated public barrel. Every export has a `show`
  list; a type is not public until it is listed there.
- `lib/src/<stage>/`: one directory per pipeline stage (see Architecture).
  `lib/src/chord_pro.dart` is the `ChordPro` entry point.
- `test/<stage>/` mirrors `lib/src/<stage>/`. `test/architecture/` enforces
  import direction; `test/spec_audit_test.dart` and
  `test/spec_coverage_test.dart` are the spec audit (see Spec-driven workflow).
- `chordpro-spec-checklist.md`: the spec distilled into obligations. Ground
  truth; edits ask first (hook).
- `doc/`: user documentation, published with the package and linked from
  pub.dev. `doc/reference/non-spec-extensions.md` and
  `doc/reference/limitations.md` are the divergence ledgers.
- `docs/`: contributor documentation, not published (`.pubignore`).
  - `docs/adr/`: architecture decisions. Read the relevant one before changing
    the pipeline, the AST's value semantics, the dependency stance or the
    audit workflow. A change that alters a decision adds or updates an ADR in
    the same PR (`.claude/rules/docs.md`).
  - `docs/brainstorm/` and `docs/plan/`: `vgv-wingspan` output. Commit each
    with the change it led to and never delete them.
- `example/chord_pro_example.dart`: the pub.dev example; must keep running.

## Commands

All commands assume the repository root as working directory.

| Task | Command |
| --- | --- |
| Install deps | `dart pub get` (the SessionStart hook does this, and installs Dart in a cloud session) |
| Format | `dart format .` |
| Static-analysis gate (= CI) | `dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos --fatal-warnings lib test example` |
| Tests | very-good-cli MCP `test` tool with `dart: true`; add `coverage: true`, `min_coverage: 85` for the CI gate |
| Tests as CI runs them | `very_good dart test --coverage --min-coverage 85 --test-randomize-ordering-seed random` (only when the MCP tool is unavailable) |
| Example | `dart run example/chord_pro_example.dart` |
| Publish check | `dart pub publish --dry-run` |

- The VGV plugin denies `dart test` and `very_good test` in the shell and
  points at its MCP `test` tool instead. The suite is ~550 tests plus a
  handful of deliberate `AUDIT:` skips and runs in seconds, so run all of
  it; the tool has no name filter.
- If the `dart` or `very-good-cli` MCP servers failed to start (no Dart on
  PATH when the session began), the SessionStart hook has since installed
  Dart and `very_good_cli`; use the CI command from the table above.
- `analyze_files` from the dart MCP server does not report every style lint,
  while CI treats infos as errors. Trust the command-line gate in the table.
- Ignore findings in `coverage/` and `.dart_tool/`; CI starts from a clean
  checkout.

## Claude Code tooling

Work here goes through the Very Good Ventures Claude Code plugins, which
`.claude/settings.json` turns on (Claude Code prompts to install them once
the folder is trusted). This file and `.claude/rules/` take precedence over
plugin skills: the plugins are written mostly for Flutter apps, and this is a
Dart library without UI, state management or localisation.

- **`vgv-ai-flutter-plugin`** provides the Dart standards and tooling.
  - Skills that apply here: `testing` (before writing tests),
    `green-gate`, `static-security`, `license-compliance`,
    `very-good-analysis-upgrade`, `dart-flutter-sdk-upgrade`. The Flutter,
    bloc, navigation, UI, theming, l10n and `layered-architecture` skills do
    not apply; the pipeline below is this repo's architecture.
  - MCP servers: `dart` (analyze, format, pub, package source search) and
    `very-good-cli` (`test`, license check).
  - Its hooks run `dart analyze` and `dart format` on every edited Dart file,
    and block shell test commands in favour of the MCP tool.
  - Its `flutter-reviewer` agent reviews changed Dart code.
- **`vgv-wingspan`** drives feature work; a one-line fix can skip it:
  `/brainstorm` (output in `docs/brainstorm/`) → `/plan` (output in
  `docs/plan/`) → `/build` → `/review`. The brainstorm and plan files are
  committed alongside the code. `/hotfix` is the short path for an urgent
  bug, `/debrief` the write-up afterwards.
  - Finish with the `ship` skill rather than `/create-pr`: `ship` knows this
    repo's gate, CHANGELOG and PR template.
- **Project skills** (`.claude/skills/`):
  - `ship` runs the gate and tests, commits, pushes and opens the PR.
  - `release` cuts a version: bump, CHANGELOG, dry-run, PR, then hands the
    tag and `dart pub publish` to the maintainer.
  - `spec-audit` refreshes the checklist against a new ChordPro release and
    closes or records audit gaps.
- **Project hooks** (`.claude/hooks/`):
  - SessionStart installs Dart and `very_good_cli` when missing, then runs
    `dart pub get`.
  - Edits outside the repo are denied.
  - Edits under `coverage/`, `.dart_tool/` and `build/` are denied.
  - Edits to `chordpro-spec-checklist.md` ask first.
- **Rules** in `.claude/rules/` are attached to path globs and load only
  when a matching file is read: `testing`, `spec-audit`, `assembler`,
  `public-api`, `docs` and `ci`.

## Architecture

The parser is a one-pass, line-oriented pipeline. Each stage lives in its own
`lib/src/<stage>/` directory and is independently testable.

```
source String
  └─ ChordPro.parse            lib/src/chord_pro.dart      public entry; altBrackets rewrite
      └─ preprocessors          lib/src/source/preprocessor.dart  user fns, per physical line
      └─ scan                  lib/src/source/scanner.dart  → List<RawLine>
      │                                                      line splitting, `\` continuation,
      │                                                      `\uXXXX` / `\u{X+}` escapes, surrogate pairs
      └─ assemble              lib/src/assembler/assembler.dart  the state machine
          ├─ parseDirectiveLine lib/src/directive/           `{name-selector: value}` → Directive
          ├─ parseKv            lib/src/directive/kv_parser  attribute soup → Map<String,String>
          ├─ tokenizeInline     lib/src/inline/              lyric line → Text/Chord/Annotation/
          │                                                  InlineDirective/ChordRecall tokens
          ├─ Chord.tryParse     lib/src/chord/chord.dart     chord string → typed Chord
          └─ reduceMetadata / reduceFormatting  lib/src/ast/  directive stream → typed Metadata,
                                                              FormattingSettings
  → ParseResult(songs, diagnostics)
```

### Layer rules

Stages form tiers, and a stage imports only stages in a lower tier.
`test/architecture/layer_boundaries_test.dart` enforces this:

| Tier | Stages |
| --- | --- |
| 0 | `util`, `source` |
| 1 | `chord`, `directive` |
| 2 | `inline` |
| 3 | `ast`, `diagnostic` (the data model; these two may import each other) |
| 4 | `assembler` |
| 5 | `lib/src/chord_pro.dart` (entry point) |

- Nothing under `lib/src/` imports the public barrel.
- A new stage directory must be added to the test's tier table.
- A type needed by a lower tier moves down (as `Preprocessor` moved into
  `source/`), rather than the lower tier importing upward.

### Structural facts

In rough order of how often they bite:

- **`assemble` is the only stateful component.** It walks `RawLine`s once,
  holding the open section, the selector-suppression state,
  `pendingTocSuppressed` from `{ns toc=…}`, and per-song `titlesAlignment` /
  `diagrams`. `finishSong()` flushes everything and is called on
  `{new_song}` and at EOF. New directive handling is a new branch in that
  loop, and order matters (`.claude/rules/assembler.md`).
- **`Song.directives` is lossless.** Every directive lands there in source
  order, including selector-suppressed ones. Typed views (`metadata`,
  `formatting`) are reductions over that stream and filter selectors
  themselves. Never drop a directive from the stream to implement a feature.
- **Selectors gate, they do not delete.** A suppressed `{start_of_X-sel}`
  still yields a `Section` with its body, flagged `isSelectorSuppressed`;
  `Song.activeSections` is the selector-honouring view.
- **`Section`/`Line` are a two-level IR.** `Line.kind` decides which fields
  are populated; verbatim kinds (`tab`, `grid`, `abc`, `ly`, `svg`,
  `textblock`, `grille`) skip inline tokenization. Content outside any
  environment goes into a synthetic `SectionKind.loose` section.
- **Everything is copy-on-transform.** `Song.transposed`, `Chord.transpose`,
  `transposeRoot` return new values; nothing in the AST mutates.
- **Config options are parameters, not globals.** A reference-implementation
  switch (`notesMode`, `strict`, `preprocessors`, `altBrackets`,
  `forceCommonKeys`) is a named parameter threaded through every layer and
  through both `ChordPro.parse` and `ChordPro.parseSong`, named after the
  spec option it mirrors.

## Spec-driven workflow

This repo is audited against the spec rather than developed feature-first.
`.claude/rules/spec-audit.md` has the detail.

- **`chordpro-spec-checklist.md`** is the ground truth. The implementation is
  checked against it, not the reverse.
- **`test/spec_audit_test.dart`** has one test per checklist item, named by
  its coordinate (`'[§4.2] …'`). Tests assert spec-correct behaviour, so a
  red test is an audit finding. Known gaps are `skip: 'AUDIT: …'`, never
  deleted.
- **`test/spec_coverage_test.dart`** runs the reverse direction: every name
  the parser dispatches on must appear in the checklist or in
  `doc/reference/non-spec-extensions.md`.
- Closing an audit gap updates the checklist item, un-skips the audit test
  and removes the limitation from `doc/reference/limitations.md` in the same
  change.

## Conventions

- Public API members carry dartdoc. Comments in `assembler.dart` cite the
  spec page or reference-implementation source line (`Song.pm:1382`) that
  justifies the behaviour.
- Parsing never throws: malformed input becomes a `Diagnostic` with a
  `DiagnosticCode` and a `SourceSpan`. Throwing is reserved for caller errors
  (bad arguments), uses a specific `Error` type (`ArgumentError`,
  `RangeError`) and is documented in the dartdoc with a `Throws` sentence.
- Every public type is an immutable value: `final` fields, structural
  `==`/`hashCode`, unmodifiable collections. `analysis_options.yaml`
  disables `avoid_equals_and_hash_code_on_mutable_classes` only because
  proving immutability to it would need `package:meta`.
- No test-only parameters on public constructors or functions. Test through
  the public API or the `src/` entry points; there is no `@visibleForTesting`
  here (it needs `package:meta`).
- Prefer named record fields; positional `$1`/`$2` access hides meaning.
- Adding a subtype to a `sealed` hierarchy (e.g. `InlineToken`) or changing
  a public signature is breaking. Pre-1.0, a break bumps the minor version.
- Commit messages are Conventional Commits with a scope; write the subject
  from a package user's point of view: `fix(assembler): keep brace-leading lines
  verbatim inside tab sections`. Scopes: `source`, `directive`, `inline`,
  `chord`, `ast`, `diagnostic`, `assembler`, `api`, `spec`, `docs`, `ci`,
  `deps`, `release`, `claude`. PR titles follow the same format (CI checks).

## Definition of done

1. Format and analyze pass for the entire repository.
2. The full suite passes with coverage at or above 85%.
3. The ledgers agree with the code: a new directive, alias or chord quality
   is in the checklist or `non-spec-extensions.md`; a new public type is in
   the barrel; a new stage is in the layer test.
4. A user-visible change has an entry under `## Unreleased` in
   `CHANGELOG.md` (`### Breaking` / `### New` / `### Fixed`, no dates).
5. The branch is pushed and a PR is open against `main` using
   `.github/PULL_REQUEST_TEMPLATE.md`.

The `ship` skill covers steps 1, 2 and 5 and only reports a PR once the
gate and the suite have passed.
