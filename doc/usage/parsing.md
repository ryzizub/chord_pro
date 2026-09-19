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

## Read the diagnostics

```dart
for (final diagnostic in result.diagnostics) {
  switch (diagnostic.code) {
    case DiagnosticCode.unterminatedSection:
      // ... a {start_of_X} with no matching end
    case DiagnosticCode.invalidNumericValue:
      // ... e.g. {capo: high}
    default:
      print(diagnostic); // "[warning] 4:1+12: ..."
  }
}
```

Every diagnostic carries a `DiagnosticCode`, a `DiagnosticSeverity` and a 1-based `SourceSpan`. Switch on the code: `message` is prose for humans and may be reworded in any release.

Parsing never throws on malformed input — problems come back as diagnostics and the parser recovers — so `result.songs` always holds at least one song.

## Compare parsed values

Every type in the AST compares structurally, so parsed songs can be diffed, deduped, cached or used as map keys:

```dart
ChordPro.parseSong(source) == ChordPro.parseSong(source); // true
```

The AST is also deeply unmodifiable: `sections`, `lines`, `tokens`, `attributes` and the metadata collections all reject mutation, and every transform (`Song.transposed`, `Chord.transpose`) returns a new value.

See also: [the `Song` model](song-model.md), [transposing and selectors](transposing.md).
