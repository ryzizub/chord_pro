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
```

`ChordPro.parse` returns a `ParseResult` with every song in the
document (split on `{new_song}` / `{ns}`) plus any diagnostics.
`ChordPro.parseSong` is a convenience that returns the first song.

Each `Song` exposes:
- `metadata` — typed `Metadata` with titles, artists, key, tempo,
  capo, transpose, columns, tags and more.
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

- Lyric/chord lines with backslash escapes for `[`, `]`, `{`, `}`.
- Chord notation: letter (A–H), Nashville, Roman; sharps, flats, both
  ASCII and unicode `♯`/`♭`; qualities (`m`, `mi`, `min`, `-`, `maj`,
  `dim`, `aug`, `sus`, `add`, `ø`, `°`); slash bass notes; `NC`.
- Section environments and chorus recall, plus delegated `abc`, `ly`,
  `svg` and `textblock` blocks captured verbatim.
- All metadata directives from the spec, including `sortartist`,
  `tag`, `transpose`, `columns`, plus `{meta: key value}` desugaring.
- Comment family (`{comment}`, `{ci}`, `{cb}`, `{highlight}`) emitted
  as in-flow comment lines.
- `{image: …}` parsed into a typed `ImageDirective`.
- Page-break and column-break directives as in-flow layout breaks.
- Font/size/colour directives (`chordfont`, `textsize`,
  `titlecolour`, …) reduced into `FormattingSettings`.
- Conditional selectors with both spec-form `-!sel` and legacy `+sel`
  negation.
- File-level `#` comments are dropped per spec.
- Diagnostics with 1-based source spans for every problem.

## Example of chordpro format

[example song](./example/knockin_on_heavens_door.cho)

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_package_badge]: https://img.shields.io/pub/v/chord_pro.svg
[pub_package_link]: https://pub.dev/packages/chord_pro
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
