# chord_pro

[![pub package][pub_package_badge]][pub_package_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A Dart parser for the [ChordPro 6 song format](https://www.chordpro.org/chordpro/home/).

Built for music apps and digital songbooks — parses `.cho` / `.crd` / `.chopro` files into typed chords, lyrics, metadata, comments, images, layout hints, and chord diagrams.

## Installation

```sh
dart pub add chord_pro
```

## Usage

### Parse a document

```dart
import 'package:chord_pro/chord_pro.dart';

final result = ChordPro.parse(source);
final song = result.songs.first;

print(song.metadata.titles.firstOrNull);
print(song.metadata.key);
```

`ChordPro.parse` returns a `ParseResult` with every song in the document (split on `{new_song}` / `{ns}`) plus any diagnostics. Use `ChordPro.parseSong` if you only want the first song.

### What a `Song` contains

- **`metadata`** — typed `Metadata`: titles, sort titles, subtitles, artists, sort artist, composers, lyricists, copyright, album, year, key, time, tempo, duration, capo, transpose, columns, tags, plus an `other` map for anything custom.
- **`sections`** — ordered `Section`s for verse, chorus, bridge, tab, grid, abc, ly, svg, textblock, custom environments, and loose lines.
- **`chordDefinitions`** — parsed `{define}` / `{chord}` bodies.
- **`formatting`** — typed font / size / colour overrides for chord, text, title, chorus, label, and friends.
- **`directives`** — the raw directive stream in source order.
- **`customExtensions`** — `x_*` namespaced directives.
- **`transposed(semitones)`** — returns a copy with every chord shifted.

### Walk sections and lines

```dart
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
```

### Transpose and conditional selectors

Shift every chord by N semitones:

```dart
final upTwo = ChordPro.parseSong(source).transposed(2);
```

Activate conditional directives like `{title-guitar: …}` / `{title-guitar!: …}` by passing a selector set:

```dart
final guitar = ChordPro.parseSong(source, selectors: {'guitar'});
```

The selector set gates metadata, formatting, sections, comments, images, layout breaks, chord recalls, and `{define}` / `{chord}` definitions. Matching is case-insensitive.

## Supported features

All facts per the [ChordPro chord reference][cp_chords] and [directive reference][cp_directives].

### Chords

- Letter roots `A`–`G`, Nashville `1`–`7`, Roman `I`–`VII`.
- Sharps and flats: `#`, `b`.
- Slash bass.
- Minor variants: `m`, `mi`, `min`, `-`.
- Major qualifier `maj` and the spec alternate `^`.
- Diminished `dim` / `0`, half-diminished `h`.
- `aug`, `sus`, `sus2`, `sus4`, `add`.

### Directives

- **Metadata** — `title` / `t`, `sorttitle`, `subtitle` / `st`, `artist`, `sortartist`, `composer`, `lyricist`, `copyright`, `album`, `year`, `key`, `time`, `tempo`, `duration`, `capo`, `transpose`, `columns` / `col`, `tag`, plus `{meta: key value}` desugaring.
- **Comments** — `{comment}`, `{ci}`, `{cb}`, `{highlight}` emit as in-flow comment lines.
- **Images** — `{image: …}` parsed into a typed `ImageDirective`.
- **Layout breaks** — `{new_page}`, `{new_physical_page}`, `{column_break}` emit as in-flow layout breaks.
- **Formatting** — `chordfont`, `textsize`, `titlecolour`, … reduce into `FormattingSettings`. Both `colour` and `color` accepted.
- **Custom** — `x_*` extensions preserved on `Song.customExtensions`.

### Sections

- Built-in environments: `verse` / `sov`, `chorus` / `soc`, `bridge` / `sob`, `tab` / `sot`, `grid` / `sog`.
- Delegated `abc`, `ly`, `svg`, `textblock` captured verbatim.
- Custom `start_of_<name>` / `end_of_<name>` sections preserved with their custom kind.

### Conditional selectors

- Positive form `{title-guitar: …}` and spec-form negation `{title-guitar!: …}`.
- Gates metadata, formatting, sections, comments, images, layout breaks, chord recalls, and `{define}` / `{chord}` definitions.

### Source features

- ChordPro 6.01 scanner: trailing `\` line continuation and `\uXXXX` Unicode escapes anywhere in input text.
- File-level `#` comments dropped.
- Diagnostics with 1-based source spans for every problem.

## Non-spec extensions

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

## Known limitations

- Only the bare `{start_of_verse: Verse 1}` form maps to `Section.label`; the `label="value"` form is parsed as raw value text.
- Pango-style markup (`<b>`, `<i>`, `<span …>`, `<sym …/>`, `<img …/>`, `<strut …/>`) inside lyrics and comments is preserved verbatim — no inline parsing.
- `{define}`'s `format` argument and the associated `\%{` escape pass through as raw value text.
- Legacy / no-op directives `pagetype`, `grid`, `no_grid`, `titles`, `diagrams` land in `Song.directives` only — no typed access.

## Example songs

Runnable demo: [`example/chord_pro_example.dart`](./example/chord_pro_example.dart).

ChordPro source files:

- [`knockin_on_heavens_door.cho`](./example/knockin_on_heavens_door.cho)
- [`house_of_the_rising_sun.cho`](./example/house_of_the_rising_sun.cho)
- [`scarborough_fair.cho`](./example/scarborough_fair.cho)

[cp_chords]: https://www.chordpro.org/chordpro/chordpro-chords/
[cp_directives]: https://www.chordpro.org/chordpro/chordpro-directives/

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_package_badge]: https://img.shields.io/pub/v/chord_pro.svg
[pub_package_link]: https://pub.dev/packages/chord_pro
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
