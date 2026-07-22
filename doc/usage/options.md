# Notes mode, strict, preprocessors

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

See also: [source features](../features/source.md), [known limitations](../reference/limitations.md).
