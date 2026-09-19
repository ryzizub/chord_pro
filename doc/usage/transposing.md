# Transpose and conditional selectors

Shift every chord by N semitones:

```dart
final upTwo = ChordPro.parseSong(source).transposed(2);
```

`transposed` normalises chord spelling as well as pitch: every letter chord comes back spelled according to `accidentals` (sharps by default). That makes a zero-step call the way to respell a song without moving it:

```dart
final inFlats = song.transposed(0, accidentals: AccidentalPreference.flats);
```

Nashville and Roman chords already abstract over key, so they pass through unchanged. Chords inside verbatim bodies — `tab`, `grid`, `abc` and the other delegated environments — are not transposed; see [known limitations](../reference/limitations.md).

Activate conditional directives like `{title-guitar: …}` / `{title-guitar!: …}` by passing a selector set:

```dart
final guitar = ChordPro.parseSong(source, selectors: {'guitar'});
```

The selector set gates metadata, formatting, sections, comments, images, layout breaks, chord recalls, and `{define}` / `{chord}` definitions. Matching is case-insensitive.

See also: [supported selector forms](../features/selectors.md).
