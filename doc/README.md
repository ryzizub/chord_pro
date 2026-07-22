# chord_pro documentation

## Usage

- [Parsing](usage/parsing.md) — parse a document, walk sections and lines.
- [The `Song` model](usage/song-model.md) — what every field holds.
- [Transposing and selectors](usage/transposing.md) — shift chords, activate conditional directives.
- [Notes mode, strict, preprocessors](usage/options.md) — `notesMode`, `strict`, `preprocessors`, `ChordRecallToken`.

## Supported features

All facts per the [ChordPro chord reference][cp_chords] and [directive reference][cp_directives].

- [Chords](features/chords.md)
- [Directives](features/directives.md)
- [Sections](features/sections.md)
- [Conditional selectors](features/selectors.md)
- [Source features](features/source.md)

## Reference

- [Non-spec extensions](reference/non-spec-extensions.md) — where the parser is more lenient than the spec.
- [Known limitations](reference/limitations.md)
- [Example songs](reference/examples.md)
- [Spec conformance checklist](../chordpro-spec-checklist.md)

[cp_chords]: https://www.chordpro.org/chordpro/chordpro-chords/
[cp_directives]: https://www.chordpro.org/chordpro/chordpro-directives/
