# 0008. Reference-implementation config options are threaded parameters

- Status: Accepted
- Date: 2026-09-27

## Context

The ChordPro reference implementation changes parsing through configuration
(`settings.notes`, `settings.strict`, `parser.preprocess`,
`parser.altbrackets`, `keys.force-common`). chord_pro has no config file and
must stay safe to call concurrently with different settings.

## Decision

Each supported option is a named parameter on both `ChordPro.parse` and
`ChordPro.parseSong`, named after the option it mirrors (`notesMode`,
`strict`, `preprocessors`, `altBrackets`, `forceCommonKeys`), and threaded
explicitly through each stage that needs it. There are no globals or
statics.

## Consequences

- Adding an option touches every layer between the entry point and the
  stage that uses it; that cost is accepted for predictability.
- Options without a parser effect (`settings.wraplines` and similar) are
  listed as limitations rather than accepted and ignored.
