# What a `Song` contains

- **`metadata`** — typed `Metadata`: titles, sortTitles, subtitles, artists, sortArtists, composers, lyricists, arrangers, copyright, album, year, keys, times, tempos, duration, capo, transpose (plus `transposeQualifier`), columns, tags, plus an `other` map for anything custom. The multi-valued fields preserve source order; convenience getters `key` / `time` / `tempo` / `sortTitle` / `sortArtist` return the first entry.
- **`sections`** — ordered `Section`s for verse, chorus, bridge, tab, grid, abc, ly, svg, textblock, grille, custom environments, and loose lines. Each section exposes `label`, `attributes`, plus typed `gridAttributes` and `textblockAttributes` where applicable.
- **`chordDefinitions`** — parsed `{define}` / `{chord}` bodies including `display`, `format`, `keys`, `copy`, `copyall`, `diagram`, and the transposable bracketed `[Name]` form.
- **`formatting`** — typed font / size / colour overrides for chord, text, title, chorus, label, and friends.
- **`directives`** — the raw directive stream in source order.
- **`customExtensions`** — `x_*` namespaced directives.
- **`tocSuppressed`** — `true` when `{ns toc=no}` requested the song be omitted from the table of contents.
- **`titlesAlignment`** — typed `{titles}` alignment hint.
- **`diagrams`** — typed `{diagrams}` (or `{g}`) setting (`enabled` flag plus position enum).
- **`transposed(semitones, {forceCommonKeys})`** — returns a copy with every chord shifted. Set `forceCommonKeys: true` to substitute enharmonic equivalents and keep ≤5 accidentals (`keys.force-common`).

See also: [parsing](parsing.md), [transposing and selectors](transposing.md), [parser options](options.md).
