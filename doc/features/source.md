# Source features

- ChordPro 6.01 scanner: trailing `\` line continuation and `\uXXXX` Unicode escapes anywhere in input text.
- ChordPro 6.060 brace-form `\u{X+}` Unicode escape (1+ hex digits, supports surrogate-pair recombination).
- File-level `#` comments dropped.
- `parser.altbrackets` configuration (`ChordPro.parse(..., altBrackets: '«»')`) rewrites the configured pair to `[` / `]` before parsing.
- `parser.preprocess` hook via `preprocessors:` — a `List<Preprocessor>` of `String Function(String line)` functions applied to every source line before scanning.
- `settings.notes` via `notesMode: true` — lowercase `a`–`g` accepted as letter-system chord roots.
- `settings.strict` via `strict: true` — emits a `DiagnosticSeverity.warning` for any song that lacks a `{key}` directive.
- `keys.force-common` via `forceCommonKeys: true` on `Song.transposed()` and `Chord.transpose()` — enharmonic substitution to keep ≤5 accidentals.
- `[^]` chord-recall operator (ChordPro 6.070, experimental) emitted as `ChordRecallToken` in the inline token stream.
- Diagnostics with 1-based source spans for every problem.

See also: [using these options](../usage/options.md).
