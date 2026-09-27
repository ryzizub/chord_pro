# 0005. Immutable value AST, copy-on-transform

- Status: Accepted
- Date: 2026-09-27

## Context

Parsed songs are cached, diffed, used as map keys and compared in tests.
Shared mutable state would make each of those unsafe.

## Decision

Every public type is an immutable value: `final` fields, unmodifiable
collections, structural `==` and `hashCode`. Transformations
(`Song.transposed`, `Chord.transpose`, `transposeRoot`) return new values
and never mutate.

## Consequences

- Tests can compare whole values instead of field by field.
- `analysis_options.yaml` switches off the one lint that cannot see this
  without `package:meta` (see ADR 0002).
