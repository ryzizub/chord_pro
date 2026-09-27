# 0002. Zero runtime dependencies

- Status: Accepted
- Date: 2026-09-27

## Context

chord_pro is a leaf library that music apps, songbook tools and servers pull
in. Every runtime dependency constrains their version solving and widens the
supply chain they inherit.

## Decision

`pubspec.yaml` has no `dependencies:`. Only `test` and `very_good_analysis`
are dev dependencies. Helpers a package would normally provide (list and map
equality, immutability) are written in `lib/src/util/`.

## Consequences

- No `package:meta`: no `@immutable`, `@visibleForTesting` or `@internal`.
  `analysis_options.yaml` disables
  `avoid_equals_and_hash_code_on_mutable_classes`, which accepts only
  `@immutable` as proof, and explains why.
- No `collection`: deep equality lives in `lib/src/util/equality.dart`.
- Adding a runtime dependency needs a new ADR superseding this one.
