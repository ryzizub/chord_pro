# Transpose and conditional selectors

Shift every chord by N semitones:

```dart
final upTwo = ChordPro.parseSong(source).transposed(2);
```

Activate conditional directives like `{title-guitar: …}` / `{title-guitar!: …}` by passing a selector set:

```dart
final guitar = ChordPro.parseSong(source, selectors: {'guitar'});
```

The selector set gates metadata, formatting, sections, comments, images, layout breaks, chord recalls, and `{define}` / `{chord}` definitions. Matching is case-insensitive.

See also: [supported selector forms](../features/selectors.md).
