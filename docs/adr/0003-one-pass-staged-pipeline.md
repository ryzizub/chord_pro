# 0003. One-pass staged pipeline with tiered imports

- Status: Accepted
- Date: 2026-09-27

## Context

ChordPro is line-oriented: a directive or a lyric line can be understood
from itself plus the state of the enclosing section and song. Keeping stages
separate lets each be tested on its own input, and lets the stateless parts
(chord grammar, directive syntax, inline tokens) be reused directly.

## Decision

Parsing is one forward pass through stages, each in its own
`lib/src/<stage>/` directory: `source` (scanning, escapes, preprocessors),
`directive` and `chord` (stateless grammars), `inline` (lyric tokens),
`ast` and `diagnostic` (the data model), `assembler` (the only stateful
stage), and `lib/src/chord_pro.dart` (the entry point).

Stages are tiered, and a stage imports only lower tiers:

| Tier | Stages |
| --- | --- |
| 0 | `util`, `source` |
| 1 | `chord`, `directive` |
| 2 | `inline` |
| 3 | `ast`, `diagnostic` |
| 4 | `assembler` |
| 5 | `lib/src/chord_pro.dart` |

`ast` and `diagnostic` may import each other: `Metadata` reports
diagnostics and `ParseResult` holds songs. Nothing in `lib/src/` imports
the public barrel. `test/architecture/layer_boundaries_test.dart` enforces
these rules.

## Consequences

- A type a lower tier needs moves down. `Preprocessor` moved from the entry
  point into `source/` when this was written, because the assembler needed it.
- A new stage directory must be added to the test's tier table, which makes
  adding one a visible decision.
