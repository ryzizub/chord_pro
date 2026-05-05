## 0.5.0

ChordPro 6 spec re-verification pass (May 2026).

* Add `+` as a spec-listed augmented quality marker — spec equivalent of
  `aug` (see <https://www.chordpro.org/chordpro/chordpro-chords/>).
  Previously `C+` was mis-parsed with extensions `['+']`; it now yields
  `quality: '+'` and empty extensions.
* Add `ImageDirective.label` typed field — the `label=` attribute was
  added to `{image}` in ChordPro 6.040
  (<https://www.chordpro.org/chordpro/directives-image/>). The value was
  already captured in `ImageDirective.attributes`; this adds a
  convenience typed accessor to match `align`, `title`, and the other
  named fields.

## 0.4.0

Spec-compliance pass against the ChordPro reference parser.

* **Breaking**: the canonical negation form is now postfix `!` —
  `{name-sel!}` — matching the ChordPro spec and the reference Perl
  parser (`s/\!$//`). `Directive.toString` emits this form. The previous
  prefix `{name-!sel}` and legacy `{name+sel}` forms continue to be
  accepted on input for backward compatibility but are now flagged as
  non-spec.
* Conditional selectors now gate **all** directives, not just metadata
  and formatting. Sections with an inactive selector skip their entire
  body (lines, nested directives, and the section end), per spec
  ("selection applies to everything in the section, up to and including
  the final section end directive"). Comments, images, layout breaks,
  chorus recalls, and `{define}`/`{chord}` definitions are likewise
  suppressed when their selector polarity does not match.
* Add the spec-listed chord qualifiers `^` (alternate for `maj`), `h`
  (half-diminished), and `0` (diminished, literal zero). The
  pre-existing `ø`/`°` glyphs remain as documented non-spec extensions.
* Add ChordPro 6.01 scanner features: `\`-terminated line continuation
  (with leading whitespace stripped from the next line) and `\uXXXX`
  Unicode escapes anywhere in the source.
* Document explicitly which features are non-spec extensions of this
  parser (German `H`, unicode accidentals, `ø`/`°`, `NC`/`N.C.`/`N.C`,
  bracket-escapes, mid-lyric directives, legacy selector forms) and
  which spec features are not yet covered (`label="…"` parsing, Pango
  markup, `{define}` format strings).

## 0.3.0

* Add `selectors:` argument to `ChordPro.parse` / `parseSong` so callers
  can activate conditional directives. The same set is forwarded to
  `reduceFormatting`, which now honours selector polarity. Matching is
  case-insensitive.
* `Directive.toString` emits a postfix `!` for negative polarity instead
  of the legacy `+sel` form.
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
