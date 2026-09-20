# Conditional selectors

- Positive form `{title-guitar: …}` and spec-form negation `{title-guitar!: …}`.
- Gates metadata, formatting, sections, comments, images, layout breaks, chord recalls, and `{define}` / `{chord}` definitions.

## Suppressed sections

A `{start_of_X-sel}` whose selector is not active still produces a `Section`,
flagged with `Section.isSelectorSuppressed` and carrying its body lines,
tokenized exactly as they would have been had the selector applied. Nothing
is dropped, so a consumer can re-emit the source or render the section
anyway.

Renderers that honour selectors should iterate `Song.activeSections`, which
is `sections` minus the suppressed ones:

```dart
final song = ChordPro.parseSong(source, selectors: {'guitar'});
for (final section in song.activeSections) {
  // ...
}
```

Directives *inside* a suppressed range are not applied and do not become
lines; they remain in `Song.directives`, in source order, like every other
directive.

Legacy negative forms the parser still accepts are listed under [non-spec extensions](../reference/non-spec-extensions.md).

Because the selector separator is a hyphen and the spec gives no way to escape it, a hyphen anywhere in a directive name is read as one: `{x_mytool-config: …}` parses as the directive `x_mytool` with the selector `config`. Use underscores in custom `x_*` directive names to avoid it.

See also: [passing a selector set](../usage/transposing.md).
