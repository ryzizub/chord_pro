# 0007. The spec checklist is ground truth, audited in both directions

- Status: Accepted
- Date: 2026-09-27 (checklist since 0.6.0, reverse coverage since 0.6.3)

## Context

Developed feature-first, the parser drifted from the spec in ways nobody
noticed, and non-spec leniencies (such as `{colb}`) shipped undocumented.

## Decision

`chordpro-spec-checklist.md` distils chordpro.org into obligations and is
the baseline the parser is checked against. `test/spec_audit_test.dart` has
one test per item, asserting what the spec says; known gaps are skipped with
an `AUDIT:` reason and listed in `doc/reference/limitations.md`.
`test/spec_coverage_test.dart` checks the reverse direction: every name the
parser dispatches on must appear in the checklist or in
`doc/reference/non-spec-extensions.md`.

## Consequences

- A red audit test is a finding about the parser, not a broken test.
- The checklist changes only when the spec changes or a gap closes; editing
  it asks first.
- A new ChordPro release means refreshing the checklist and re-running the
  audit (the `spec-audit` skill).
