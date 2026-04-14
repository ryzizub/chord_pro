### ChordPro

[![pub package][pub_package_badge]][pub_package_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

The ChordPro Library is a comprehensive Dart package designed for parsing ChordPro format files. Ideal for music app developers and digital songbook creators, this library offers efficient parsing of ChordPro files, extracting chords, lyrics, and metadata for seamless integration into Dart and Flutter applications.

## Using

```dart
import 'package:chord_pro/chord_pro.dart';

final result = ChordPro.parse(source);
for (final song in result.songs) {
  print(song.metadata.titles.firstOrNull);
  for (final section in song.sections) {
    print('${section.kind} ${section.label ?? ''}');
    for (final line in section.lines) {
      for (final token in line.tokens) {
        // TextToken / ChordToken / AnnotationToken / InlineDirectiveToken
      }
    }
  }
}
```

`ChordPro.parse` returns a `ParseResult` with every song in the
document (split on `{new_song}` / `{ns}`) plus any diagnostics.
`ChordPro.parseSong` is a convenience that returns the first song.

Each `Song` exposes:
- `metadata` — typed `Metadata` with titles, artists, key, tempo, etc.
- `sections` — ordered `Section`s for verses, choruses, bridges,
  tabs, grids, abc, ly, and custom environments, plus loose lines.
- `chordDefinitions` — parsed `{define}` / `{chord}` bodies.
- `directives` — the raw directive stream in source order.

## Example of chordpro format

[example song](./example/knockin_on_heavens_door.cho)

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_package_badge]: https://img.shields.io/pub/v/chord_pro.svg
[pub_package_link]: https://pub.dev/packages/chord_pro
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
