### ChordPro

[![pub package][pub_package_badge]][pub_package_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

A Dart parser for the [ChordPro 6 file format](https://www.chordpro.org/chordpro/home/).
Built for music app developers and digital songbook tooling: extract
chords, lyrics, metadata, comments, images, layout hints and chord
diagrams from `.cho`/`.crd`/`.chopro` files.

## Using

```dart
import 'package:chord_pro/chord_pro.dart';

final result = ChordPro.parse(source);
for (final song in result.songs) {
  print(song.metadata.titles.firstOrNull);
  for (final section in song.sections) {
    print('${section.kind} ${section.label ?? ''}');
    for (final line in section.lines) {
      switch (line.kind) {
        case LineKind.structured:
          for (final token in line.tokens) {
            // TextToken / ChordToken / AnnotationToken / InlineDirectiveToken
          }
        case LineKind.verbatim:
          print(line.verbatim);
        case LineKind.comment:
          print('${line.commentStyle}: ${line.comment}');
        case LineKind.image:
          print('image: ${line.image?.src}');
        case LineKind.layoutBreak:
          print('break: ${line.layoutBreak}');
      }
    }
  }
}

// Transposition.
final upTwo = ChordPro.parseSong(source).transposed(2);

// Conditional selectors (e.g. instrument-specific titles).
final guitar = ChordPro.parseSong(source, selectors: {'guitar'});
```

`ChordPro.parse` returns a `ParseResult` with every song in the
document (split on `{new_song}` / `{ns}`) plus any diagnostics.
`ChordPro.parseSong` is a convenience that returns the first song.
Pass `selectors:` to activate conditional directives — see below.

Each `Song` exposes:
- `metadata` — typed `Metadata` with titles, sort titles, subtitles,
  artists, sort artist, composers, lyricists, copyright, album,
  year, key, time, tempo, duration, capo, transpose, columns, tags
  and an `other` map for anything custom.
- `sections` — ordered `Section`s for verses, choruses, bridges,
  tabs, grids, abc, ly, svg, textblock and custom environments,
  plus loose lines.
- `chordDefinitions` — parsed `{define}` / `{chord}` bodies.
- `formatting` — typed font/size/colour overrides for chord, text,
  title, chorus, label and friends.
- `directives` — the raw directive stream in source order.
- `customExtensions` — `x_*` namespaced directives.
- `transposed(semitones)` — returns a copy with every chord shifted.

## Supported features

- Spec-conformant chord notation per the [ChordPro reference][cp_chords]:
  letter roots (`A`–`G`), Nashville (`1`–`7`), Roman (`I`–`VII`); sharps
  and flats (`#`/`b`); slash bass; minor variants `m`/`mi`/`min`/`-`;
  major qualifiers `maj` and the spec alternate `^`; diminished `dim`
  and the literal-zero `0`; half-diminished `h`; `aug`, `sus`/`sus2`/
  `sus4`, `add`.
- Conditional directives — both positive (`{title-guitar: …}`) and
  spec-form negation (`{title-guitar!: …}`, with `!` postfixed on the
  selector per the [ChordPro reference parser][cp_directives]). Pass
  `selectors:` to `ChordPro.parse` / `parseSong` to activate them; the
  same set gates metadata, formatting, sections, comments, images,
  layout breaks, chord recalls, and `{define}`/`{chord}` definitions.
- All section environments — `verse`/`sov`, `chorus`/`soc`, `bridge`/
  `sob`, `tab`/`sot`, `grid`/`sog`, plus delegated `abc`, `ly`, `svg`
  and `textblock` captured verbatim. Custom `start_of_<name>` /
  `end_of_<name>` sections preserved with their custom kind.
- All metadata directives from the spec — `title`/`t`, `sorttitle`,
  `subtitle`/`st`, `artist`, `sortartist`, `composer`, `lyricist`,
  `copyright`, `album`, `year`, `key`, `time`, `tempo`, `duration`,
  `capo`, `transpose`, `columns`/`col`, `tag` — plus `{meta: key
  value}` desugaring.
- Comment family (`{comment}`, `{ci}`, `{cb}`, `{highlight}`) emitted
  as in-flow comment lines.
- `{image: …}` parsed into a typed `ImageDirective`.
- Page-break and column-break directives as in-flow layout breaks
  (`{new_page}`, `{new_physical_page}`, `{column_break}`).
- Font/size/colour directives (`chordfont`, `textsize`,
  `titlecolour`, …) reduced into `FormattingSettings`. Both `colour`
  and the American `color` spelling are accepted.
- Custom `x_*` extensions preserved on `Song.customExtensions` and
  silently ignored by typed reduction (per spec).
- File-level `#` comments dropped.
- ChordPro 6.01 features: trailing `\`-line continuation and
  `\uXXXX` Unicode escapes in any input text.
- Diagnostics with 1-based source spans for every problem.

## Non-spec extensions

For ergonomic reasons this parser is more lenient than the published
spec in a few places. Each is opt-in by simply being present in the
input — your file will still parse, but the named feature is **not**
required by ChordPro itself:

- `H` as a letter root (German notation for B natural).
- Unicode accidentals `♯` (U+266F) and `♭` (U+266D).
- Half-diminished `ø` and diminished `°` glyphs (the spec marks these
  as `h` and `0`/`dim`).
- No-chord markers `NC`, `N.C.`, `N.C` (the spec is silent).
- Backslash-escapes for `[`, `]`, `{`, `}`, `\` inside lyric lines.
- `{…}` directives appearing mid-lyric (the spec requires directives
  to occupy a whole line).
- Legacy negative-selector forms `{name-!sel}` and `{name+sel}`,
  retained for backward compatibility with older files. New files
  should use the spec form `{name-sel!}`.

## Known limitations

- The `label="value"` form for section labels is parsed as raw value
  text; only the bare `{start_of_verse: Verse 1}` form is mapped to
  `Section.label`.
- Pango-style markup (`<b>`, `<i>`, `<span …>`, `<sym …/>`, `<img …/>`,
  `<strut …/>`) inside lyric/comment text is preserved verbatim — no
  inline parsing is performed.
- `{define}`'s `format` argument and the associated `\%{` escape are
  passed through as raw value text.
- The legacy/no-op directives `pagetype`, `grid`, `no_grid`, `titles`,
  and `diagrams` land in `Song.directives` only — they are not given
  typed access.

## Example of chordpro format

[example song](./example/knockin_on_heavens_door.cho)

[cp_chords]: https://www.chordpro.org/chordpro/chordpro-chords/
[cp_directives]: https://www.chordpro.org/chordpro/chordpro-directives/

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_package_badge]: https://img.shields.io/pub/v/chord_pro.svg
[pub_package_link]: https://pub.dev/packages/chord_pro
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
