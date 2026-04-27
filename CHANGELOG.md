## 0.3.0

* Add `selectors:` argument to `ChordPro.parse` / `parseSong` so callers
  can activate conditional directives. The same set is forwarded to
  `reduceFormatting`, which now honours selector polarity. Matching is
  case-insensitive.
* `Directive.toString` emits the spec form `{name-!sel}` for negative
  polarity instead of the legacy `+sel` form.
* Drop the unused `collection` dependency.

## 0.2.0

* Skip `#` file-comment lines per spec.
* Add `sortartist` and `tag` metadata fields.
* Accept spec-form `{name-!sel: …}` selector negation alongside the
  legacy `+sel` form.
* Emit `{comment}` / `{comment_italic}` (`ci`) / `{comment_box}` (`cb`)
  / `{highlight}` as `Line.comment` entries.
* Parse `{image: …}` into a typed `ImageDirective` exposed as
  `Line.image` entries.
* Add `Chord.transpose`, `Song.transposed`, and `metadata.transpose`.
* Recognise `{new_page}` / `{new_physical_page}` / `{column_break}` as
  `Line.layoutBreak` entries; capture `{columns}` / `{col}` as
  `metadata.columns`.
* Add `svg` and `textblock` verbatim section kinds.
* Reduce font/size/colour directives into `Song.formatting`
  (`FormattingSettings` keyed by target).
* Recognise `x_*` custom-extension directives via
  `Directive.isCustomExtension` and `Song.customExtensions`.
* Extend the chord parser to handle German `H`, unicode `♯`/`♭`,
  minor variants (`mi`, `-`), half-diminished `ø`, diminished `°`,
  and `NC`/`N.C.` no-chord markers.

## 0.1.0

* Intial
