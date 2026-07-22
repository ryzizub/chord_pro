# Known limitations

- Pango-style markup (`<b>`, `<i>`, `<span …>`, `<sym …/>`, `<img …/>`, `<strut …/>`) inside lyrics and comments is preserved verbatim — no inline parsing or rendering.
- `{define format="…"}` is captured as a typed `String` but the `%{…}` substitutions inside it are not interpreted (rendering concern).
- The directive parser closes on the first unescaped `}`, so attribute values cannot themselves contain a literal `}`.
- `{pagetype}` lands in `Song.directives` only — no typed access.
- The `[^]` chord-recall operator (ChordPro 6.070, experimental) is emitted as a `ChordRecallToken` in the inline token stream; advancing the active cc-set cursor is a rendering concern.
- Chord-over-lyrics legacy auto-conversion (`chords-over-lyrics/`) is not implemented; supply ChordPro-format input.
- The `preprocessors` hook applies a single rewrite function to every source line. Selective preprocessing by line type (`parser.preprocess.directive`, `parser.preprocess.songline`, `parser.preprocess.env-<name>`), regex patterns, and the `flags`/`select` rewrite-item keys have no surface.
- Configuration-only switches (`settings.wraplines`, `settings.choruslabels`, `settings.maj7delta`) have no surface — the parser uses the ChordPro 6.100 defaults.
