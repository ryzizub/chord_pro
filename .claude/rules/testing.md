---
paths:
  - "test/**"
---

# Testing

- Run tests through the very-good-cli MCP `test` tool (`dart: true`). Shell
  `dart test` is blocked by the VGV plugin hook. Run the whole suite; it is
  fast and the tool has no name filter.
- CI runs with `--test-randomize-ordering-seed random`. No test may depend on
  another's side effects; build inputs inside the test or in `setUp`.
- `test/<stage>/` mirrors `lib/src/<stage>/`, one `_test.dart` per source
  file where practical. Cross-stage behaviour goes in `test/chord_pro_test.dart`
  or the spec audit, not in a stage directory.
- Group by the unit under test, name tests as a sentence about behaviour:
  `group('Chord.tryParse', …)` / `test('keeps altered fifths in the extension', …)`.
- Prefer parsing real ChordPro text through `ChordPro.parse` over hand-built
  `RawLine`s; import `package:chord_pro/src/…` only for a stage that has no
  public entry point.
- Assert on whole values where the type compares structurally (every AST
  type does): `expect(song.sections.first, Section(...))` catches fields you
  forgot; a list of `expect(x.field, …)` lines does not.
- Diagnostics are part of behaviour. Assert `result.diagnostics` (code and
  span) whenever the input is malformed, and assert it is empty when it isn't.
- No mocks: there are no collaborators to mock and no `mocktail` dependency.
- Tests in `test/spec_audit_test.dart` and `test/spec_coverage_test.dart`
  follow `.claude/rules/spec-audit.md`, not this file.
- `test/architecture/layer_boundaries_test.dart` is the import-direction
  gate. Fix the import, don't widen the tier table, unless the change is an
  intended architecture change with an ADR.
- Coverage must stay at or above 85% (CI gate). A new branch in the
  assembler gets a test that reaches it.
