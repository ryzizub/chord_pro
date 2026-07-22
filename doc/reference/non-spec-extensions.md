# Non-spec extensions

The parser is more lenient than the published spec in a few places. Each extension is opt-in by simply being present in your input — files parse either way, but the named feature is **not** required by ChordPro itself.

| Extension                       | Spec equivalent      | Notes                                                  |
|---------------------------------|----------------------|--------------------------------------------------------|
| `H` letter root                 | `B`                  | German notation for B natural.                         |
| `♯` (U+266F), `♭` (U+266D)      | `#`, `b`             | Unicode accidentals.                                   |
| `ø`, `°`                        | `h`, `0` / `dim`     | Half-diminished and diminished glyphs.                 |
| `NC`, `N.C.`, `N.C`             | —                    | No-chord markers; spec is silent.                      |
| Backslash escapes inside lyrics | —                    | Escape `[`, `]`, `{`, `}`, `\` inside lyric lines.     |
| Mid-lyric `{…}` directives      | —                    | Spec requires directives to occupy a whole line.       |
| `{name-!sel}`, `{name+sel}`     | `{name-sel!}`        | Legacy negative-selector forms; new files use the spec form. |
