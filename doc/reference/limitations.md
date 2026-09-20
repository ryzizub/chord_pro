# Known limitations

- Pango-style markup (`<b>`, `<i>`, `<span …>`, `<sym …/>`, `<img …/>`, `<strut …/>`) inside lyrics and comments is preserved verbatim — no inline parsing or rendering.
- `{define format="…"}` is captured as a typed `String` but the `%{…}` substitutions inside it are not interpreted (rendering concern).
- The directive parser closes on the first unescaped `}`, so attribute values cannot themselves contain a literal `}`.
- `{pagetype}` lands in `Song.directives` only — no typed access.
- The `[^]` chord-recall operator (ChordPro 6.070, experimental) is emitted as a `ChordRecallToken` in the inline token stream; advancing the active cc-set cursor is a rendering concern.
- `{start_of_grid}` bodies are captured verbatim, so the grid token vocabulary (`.` empty cell, `/` play-here, `~` multi-chord cell, bar and volta symbols, `%`/`%%` repeats, and the 6.080 strum indicators) is not surfaced as tokens, and `Song.transposed` leaves chords inside a grid at their original pitch.
- `{transpose}` does not cascade into `{start_of_abc}` bodies, which the spec says it should; ABC bodies are handed to the delegate exactly as written. Use the ABC `%%transpose` directive instead.
- Chord-over-lyrics legacy auto-conversion (`chords-over-lyrics/`) is not implemented; supply ChordPro-format input.
- The `preprocessors` hook applies a single rewrite function to every source line. Selective preprocessing by line type (`parser.preprocess.directive`, `parser.preprocess.songline`, `parser.preprocess.env-<name>`), regex patterns, and the `flags`/`select` rewrite-item keys have no surface.
- Configuration-only switches (`settings.wraplines`, `settings.choruslabels`, `settings.maj7delta`) have no surface — the parser uses the ChordPro 6.100 defaults.
