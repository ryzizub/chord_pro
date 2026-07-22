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
print(song.metadata.key); // first key (use `metadata.keys` for the full list)
```

`ChordPro.parse` returns a `ParseResult` with every song in the document (split on `{new_song}` / `{ns}`) plus any diagnostics. Use `ChordPro.parseSong` if you only want the first song.

### What a `Song` contains

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

### Notes mode, strict, preprocessors

```dart
// settings.notes: accept lowercase a–g as chord roots
final song = ChordPro.parseSong(source, notesMode: true);

// settings.strict: warn when no {key} directive is present
final result = ChordPro.parse(source, strict: true);
for (final d in result.diagnostics) { /* check d.severity */ }

// parser.preprocess: rewrite each source line before parsing
final song2 = ChordPro.parseSong(
  source,
  preprocessors: [
    (line) => line.replaceAll('«', '[').replaceAll('»', ']'),
  ],
);
```

`ChordRecallToken` — emitted in the inline token stream when `[^]` appears (the ChordPro 6.070 chord-recall operator). Renderers should advance their active cc-set cursor when they encounter it.

## Supported features

All facts per the [ChordPro chord reference][cp_chords] and [directive reference][cp_directives].

### Chords

- Letter roots `A`–`G`, Nashville `1`–`7`, Roman `I`–`VII`.
- Sharps and flats: `#`, `b`.
- Slash bass.
- Minor variants: `m`, `mi`, `min`, `-`.
- Major qualifier `maj` and the spec alternate `^`.
- Diminished `dim` / `0`, half-diminished `h`.
- Augmented `aug` and the spec alternate `+`.
- `sus`, `sus2`, `sus4`, `add`.
- Emergency-bracket recovery (ChordPro 6.020/6.080): `[ ]+` and `[|]` parse as annotations; empty `[]` is a zero-width placeholder.

### Directives

- **Metadata** — `title` / `t`, `sorttitle`, `subtitle` / `st`, `artist`, `sortartist`, `composer`, `lyricist`, `arranger`, `copyright`, `album`, `year`, `key`, `time`, `tempo`, `duration`, `capo`, `transpose` (with optional `s`/`f`/`k`/`#`/`b`/`♯`/`♭` qualifier), `columns` / `col`, `tag`, plus `{meta: key value}` desugaring. `key`, `time`, `tempo`, `sorttitle`, and `sortartist` are multi-valued per spec (one `sorttitle` per `title`; each `{key}` applies from its source position). Auto-generated names (`_key`, `key.print`, `today`, `instrument`, `user`, `page`, …) are reserved.
- **Comments** — `{comment}`, `{ci}`, `{cb}`, `{highlight}` emit as in-flow comment lines.
- **Images** — `{image: …}` parsed into a typed `ImageDirective` with full attribute coverage: `src`, `width`, `height`, `scale`, `align`, `border`, `bordertrbl` (`trbl=` accepted as alias), `title`, `label`, `href`, `id`, `chord`, `type`, `x`, `y`, `spread`, `center`, `persist`, `omit`, plus a validated `anchorEnum` (`paper` / `page` / `allpages` / `column` / `float` / `line`).
- **Layout breaks** — `{new_page}`, `{new_physical_page}`, `{column_break}` emit as in-flow layout breaks.
- **Output / song boundary** — `{ns toc=no}` (or `toc=false` / `toc=0`) sets `Song.tocSuppressed`. `{titles: left|center|right}` and `{diagrams: on|off|top|bottom|right|below}` (with `{g}` alias) become typed song-level settings.
- **Formatting** — `chordfont`, `textsize`, `titlecolour`, … reduce into `FormattingSettings`. Both `colour` and `color` accepted.
- **Custom** — `x_*` extensions preserved on `Song.customExtensions`.

### Sections

- Built-in environments: `verse` / `sov`, `chorus` / `soc`, `bridge` / `sob`, `tab` / `sot`, `grid` / `sog`.
- Delegated `abc`, `ly`, `svg`, `textblock` captured verbatim.
- Custom `start_of_<name>` / `end_of_<name>` sections preserved with their custom kind.
- `label="…"` attribute parsed for every `{start_of_*}` (alongside the legacy bare-value form).
- `{start_of_grid}` exposes typed `shape` (left+measures × beats+right), `cc` (plus decoded `ccName` / `ccProgression` for the 6.070 `cc="Name:C1 C2 …"` form), and `label` via `Section.gridAttributes`.
- `{start_of_textblock}` exposes the full ChordPro 6.050 attribute set (textblock-specific plus image-inherited) via `Section.textblockAttributes`.
- `{chorus}` recall accepts all four spec forms — `{chorus}`, `{chorus: Final}`, `{chorus: label="Final"}`, `{chorus label="Final"}`.

### Conditional selectors

- Positive form `{title-guitar: …}` and spec-form negation `{title-guitar!: …}`.
- Gates metadata, formatting, sections, comments, images, layout breaks, chord recalls, and `{define}` / `{chord}` definitions.

### Source features

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

- Pango-style markup (`<b>`, `<i>`, `<span …>`, `<sym …/>`, `<img …/>`, `<strut …/>`) inside lyrics and comments is preserved verbatim — no inline parsing or rendering.
- `{define format="…"}` is captured as a typed `String` but the `%{…}` substitutions inside it are not interpreted (rendering concern).
- The directive parser closes on the first unescaped `}`, so attribute values cannot themselves contain a literal `}`.
- `{pagetype}` lands in `Song.directives` only — no typed access.
- The `[^]` chord-recall operator (ChordPro 6.070, experimental) is emitted as a `ChordRecallToken` in the inline token stream; advancing the active cc-set cursor is a rendering concern.
- Chord-over-lyrics legacy auto-conversion (`chords-over-lyrics/`) is not implemented; supply ChordPro-format input.
- The `preprocessors` hook applies a single rewrite function to every source line. Selective preprocessing by line type (`parser.preprocess.directive`, `parser.preprocess.songline`, `parser.preprocess.env-<name>`), regex patterns, and the `flags`/`select` rewrite-item keys have no surface.
- Configuration-only switches (`settings.wraplines`, `settings.choruslabels`, `settings.maj7delta`) have no surface — the parser uses the ChordPro 6.100 defaults.

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
