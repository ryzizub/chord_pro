# chord_pro

[![pub package][pub_package_badge]][pub_package_link]
[![ci][ci_badge]][ci_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A Dart parser for the [ChordPro 6 song format](https://www.chordpro.org/chordpro/home/).

Built for music apps and digital songbooks — parses `.cho` / `.crd` / `.chopro` files into typed chords, lyrics, metadata, comments, images, layout hints, and chord diagrams.

Zero runtime dependencies. Parsing never throws: problems come back as diagnostics with a stable code and a source span. The whole AST is immutable and compares by value, so parsed songs can be diffed, cached or used as map keys.

## Features

- **ChordPro 6 spec coverage**, audited item by item against a [spec checklist](./chordpro-spec-checklist.md).
- **Transposition** of whole songs or single chords.
- **Conditional selectors** (`{title-guitar: …}`) activated by passing a selector set.
- **Diagnostics** with a stable code and source span instead of exceptions.
- **Immutable AST** that compares by value.

## Installation

```sh
dart pub add chord_pro
```

## Quick start

```dart
import 'package:chord_pro/chord_pro.dart';

void main() {
  final song = ChordPro.parseSong('''
{title: Amazing Grace}
{start_of_verse: Verse 1}
A[G]mazing [G7]grace, how [C]sweet the [G]sound
{end_of_verse}
''');

  print(song.metadata.titles.first); // Amazing Grace
  for (final section in song.sections) {
    for (final line in section.lines) {
      // (G, G7, C, G)
      print(line.tokens.whereType<ChordToken>().map((t) => t.raw));
    }
  }
}
```

Use `ChordPro.parse` for documents with several songs (`{new_song}`) and to read diagnostics.

## Documentation

Full docs live in [`doc/`](./doc/README.md).

**Usage**

- [Parsing](./doc/usage/parsing.md) — parse a document, walk sections and lines.
- [The `Song` model](./doc/usage/song-model.md) — what every field holds.
- [Transposing and selectors](./doc/usage/transposing.md) — shift chords, activate conditional directives.
- [Notes mode, strict, preprocessors](./doc/usage/options.md) — parser options.

**Supported features**

- [Chords](./doc/features/chords.md)
- [Directives](./doc/features/directives.md)
- [Sections](./doc/features/sections.md)
- [Conditional selectors](./doc/features/selectors.md)
- [Source features](./doc/features/source.md)

**Reference**

- [Non-spec extensions](./doc/reference/non-spec-extensions.md)
- [Known limitations](./doc/reference/limitations.md)
- [Example songs](./doc/reference/examples.md)

[ci_badge]: https://github.com/ryzizub/chord_pro/actions/workflows/ci.yaml/badge.svg
[ci_link]: https://github.com/ryzizub/chord_pro/actions/workflows/ci.yaml
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_package_badge]: https://img.shields.io/pub/v/chord_pro.svg
[pub_package_link]: https://pub.dev/packages/chord_pro
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
