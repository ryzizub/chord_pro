# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`chord_pro` — a pure-Dart parser for the [ChordPro 6 song format](https://www.chordpro.org/chordpro/). Zero runtime dependencies; `test` and `very_good_analysis` are the only dev dependencies. Published to pub.dev.

## Commands

```bash
dart pub get
dart analyze --fatal-infos
dart format .
dart run example/chord_pro_example.dart
```

**Tests: a hook blocks bare `dart test`** — run them through the `very_good_cli` MCP `test` tool with `dart: true` (add `coverage: true`, `min_coverage: 85` to reproduce the CI gate). The suite is ~430 tests plus 4 deliberate `AUDIT:` skips and finishes in a few seconds, so running all of it is the normal loop; the tool has no name/path filter.

Coverage locally without the MCP tool:

```bash
dart pub global activate coverage && dart pub global run coverage:test_with_coverage
```

CI (`.github/workflows/ci.yaml`) runs, in order: `dart format --output=none --set-exit-if-changed .`, `dart analyze --fatal-infos`, tests with coverage, then the 85% gate. Formatting and `--fatal-infos` are hard failures — run both before pushing.

## Architecture

The parser is a one-pass, line-oriented pipeline. Each stage lives in its own `lib/src/<stage>/` directory and is independently testable; `test/` mirrors that layout.

```
source String
  └─ ChordPro.parse            lib/src/chord_pro.dart      public entry; altBrackets rewrite
      └─ preprocessors          (user Preprocessor fns, applied per physical line)
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

Key structural facts, in rough order of how often they bite:

- **`assemble` is the only stateful component.** It walks `RawLine`s once, holding: the open section, a `skipUntilEnd` marker for selector-suppressed sections, `pendingTocSuppressed` from `{ns toc=…}`, and per-song `titlesAlignment` / `diagrams`. `finishSong()` flushes everything and is called on `{new_song}` and at EOF. New directive handling is a new branch in that loop; order matters (song boundary → song-level settings → selector gate → definitions → chorus recall → section start/end → comment/layout/image → fallthrough).
- **`Song.directives` is lossless.** Every directive lands there in source order, including ones that are selector-suppressed or otherwise skipped. Typed views (`metadata`, `formatting`) are *reductions* over that stream and filter selectors themselves. Never drop a directive from the stream to implement a feature.
- **Selectors gate, they do not delete.** `_selectorApplies` decides whether a directive contributes; a suppressed `{start_of_X-sel}` sets `skipUntilEnd` so every line through the matching `end_of_X` is dropped from sections while still being recorded as directives.
- **`Section`/`Line` are a two-level IR.** `Line.kind` (`structured` / `verbatim` / `comment` / `image` / `layoutBreak`) determines which fields are populated — verbatim kinds (`tab`, `grid`, `abc`, `ly`, `svg`, `textblock`, `grille`) skip inline tokenization entirely. Content outside any environment goes into a synthetic `SectionKind.loose` section.
- **Everything is copy-on-transform.** `Song.transposed`, `Chord.transpose`, `transposeRoot` return new values; no in-place mutation anywhere in the AST.
- **`lib/chord_pro.dart` is a curated barrel.** Every export uses an explicit `show` list. A new public type is not public until it is added there — check the barrel when adding one.

### ChordPro configuration options

Config switches from the reference implementation are surfaced as named parameters threaded down the pipeline, not as global state. `notesMode` (`settings.notes`) reaches `Chord.tryParse` through `ChordPro.parse` → `assemble` → `_OpenSection` → `tokenizeInline`; `strict`, `preprocessors`, `altBrackets`, `forceCommonKeys` follow the same pattern at their own layers. When adding one, thread it through every layer *and* both `ChordPro.parse` and `ChordPro.parseSong`, and name it after the spec option it mirrors.

## Spec-driven workflow

This repo is audited against the spec rather than developed feature-first.

- **`chordpro-spec-checklist.md`** is the ground-truth baseline — every directive, grammar rule, and token distilled from chordpro.org, with `[ ]` / `[x]` obligations and `since:` versions. It is the audit source; the implementation is checked against it, not the reverse. Don't edit it casually. When ChordPro publishes a release, refresh the banner at the top and re-run the audit suite.
- **`test/spec_audit_test.dart`** maps one test per checklist item; the test name carries the checklist coordinate (`'[§4.2] …'`). Tests assert **spec-correct** behaviour, not current behaviour — a red test is an audit finding, not a broken test. Known gaps are recorded as `skip: 'AUDIT: …'` with the reason, never deleted.
- **`test/<area>/`** holds the ordinary unit tests, mirroring `lib/src/<area>/`.
- Deliberate divergences go in the README, in one of two tables: **Non-spec extensions** (parser is more lenient than the spec) or **Known limitations** (spec feature not implemented, usually a rendering concern). Closing an audit gap means updating the checklist item, un-skipping the audit test, and removing the README limitation in the same change.

## Conventions

- Lints: `very_good_analysis`. Public API members carry dartdoc; comments in `assembler.dart` cite the spec page or reference-implementation source line (`Song.pm:1382`) that justifies the behaviour — keep that habit when adding branches.
- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor!:`). Work happens on branches merged to `main` via PR (`.github/PULL_REQUEST_TEMPLATE.md`).
- Releases: bump `version` in `pubspec.yaml` and add a `CHANGELOG.md` section with `### Breaking` / `### New` / `### Fixed` subsections. Entries describe the API change and link the spec page. Adding a subtype to a `sealed` hierarchy (e.g. `InlineToken`) is breaking — call it out.
