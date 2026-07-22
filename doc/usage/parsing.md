# Parsing

## Parse a document

```dart
import 'package:chord_pro/chord_pro.dart';

final result = ChordPro.parse(source);
final song = result.songs.first;

print(song.metadata.titles.firstOrNull);
print(song.metadata.key); // first key (use `metadata.keys` for the full list)
```

`ChordPro.parse` returns a `ParseResult` with every song in the document (split on `{new_song}` / `{ns}`) plus any diagnostics. Use `ChordPro.parseSong` if you only want the first song.

## Walk sections and lines

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

See also: [the `Song` model](song-model.md), [transposing and selectors](transposing.md).
