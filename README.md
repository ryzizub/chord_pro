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

## Quick start

```dart
import 'package:chord_pro/chord_pro.dart';

final result = ChordPro.parse(source);
final song = result.songs.first;

print(song.metadata.titles.firstOrNull);
print(song.metadata.key); // first key (use `metadata.keys` for the full list)
```

`ChordPro.parse` returns a `ParseResult` with every song in the document (split on `{new_song}` / `{ns}`) plus any diagnostics. Use `ChordPro.parseSong` if you only want the first song.

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

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_package_badge]: https://img.shields.io/pub/v/chord_pro.svg
[pub_package_link]: https://pub.dev/packages/chord_pro
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
