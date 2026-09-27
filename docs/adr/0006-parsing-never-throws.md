# 0006. Parsing never throws; problems are coded diagnostics

- Status: Accepted
- Date: 2026-09-27 (codes required since 0.7.0)

## Context

ChordPro files are hand-written and often malformed. An app parsing a user's
songbook should get as much of each song as can be recovered, plus a list of
problems it can show or filter.

## Decision

`ChordPro.parse` and `ChordPro.parseSong` never throw on malformed input.
Each problem becomes a `Diagnostic` with a required, stable `DiagnosticCode`,
a severity and a `SourceSpan`, returned in `ParseResult.diagnostics`.
Throwing is reserved for caller errors (an invalid argument), uses a
specific `Error` subtype and is documented in the dartdoc.

## Consequences

- New malformed-input handling adds or reuses a `DiagnosticCode`; codes are
  public API, so renaming one is breaking.
- `strict` mode raises more diagnostics; it does not make parsing throw.
