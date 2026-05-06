## Unreleased

### Bug fixes / spec parity

* `{grid}` now enables chord-diagram display (`Song.diagrams.enabled =
  true`), matching the reference `dir_grid` handler (Song.pm). Previously
  a bare `{grid}` directive was silently ignored.
  Spec: <https://www.chordpro.org/chordpro/directives-diagrams/>
* `{no_grid}` now disables chord-diagram display (`Song.diagrams.enabled =
  false`), matching the reference `dir_no_grid` handler.
  Spec: <https://www.chordpro.org/chordpro/directives-diagrams/>
* `{ng}` is now recognised as the spec-listed abbreviation for `{no_grid}`
  (from the Song.pm `%abbrevs` hash: `ng => "no_grid"`). Previously `{ng}`
  was silently dropped.
  Spec: <https://www.chordpro.org/chordpro/directives-diagrams/>

---

## 0.5.0

ChordPro 6 spec parity pass against the upstream reference parser
(`ChordPro/chordpro` head, currently 6.101). Net additive surface — no
breaking changes from 0.4.0.

### New typed accessors

* `Metadata.arrangers` (list, like `composers` and `lyricists`).
  Spec: <https://www.chordpro.org/chordpro/directives-arranger/>.
* `Metadata.transposeQualifier` (TransposeQualifier enum: `none`,
  `sharps`, `flats`, `followKey`). Captures the postfix
  `s | # | ♯ | f | b | ♭ | k` on `{transpose: N…}` per
  `Transpose.pm:114`. The `k` qualifier was added in ChordPro 6.100.
* `ImageDirective.label` (visible caption, ChordPro 6.040), `.href`
  (6.060), `.x`, `.y`, `.spread`, `.bordertrbl`, `.center`, `.chord`,
  `.type`, `.persist`, `.omit`.
* `ImageDirective.anchorEnum` (`ImageAnchor` enum: `paper`, `page`,
  `allpages`, `column`, `float`, `line`). `allpages` was added in
  ChordPro 6.080.
* `ChordDefinition.display` (5.989), `.format`, `.keys` (0.979),
  `.copy`, `.copyall`, `.diagram` (6.010), `.isTransposable` (6.100).
  Fingers may now be string letters (`A`–`M`, `O`–`W`, `Y`, `Z`) in
  addition to integers and muted markers.
* `Section.label` is now populated from `{start_of_*: label="…"}` as
  well as the legacy bare-value form. `Section.attributes` exposes
  any extra KV pairs.
* `Section.gridAttributes` (`GridAttributes` with `shape`, `cc`,
  `label` — `cc` defaults to `"grid"` per spec).
* `Section.textblockAttributes` (`TextblockAttributes` covering the
  full ChordPro 6.050 attribute set plus image-inherited fields).
* `Song.tocSuppressed` (from `{ns toc=no}`, ChordPro 6.040).
* `Song.titlesAlignment` (`TitlesAlignment.left|center|right`;
  `centre` accepted as alias).
* `Song.diagrams` (`DiagramsSetting{enabled, position}`; position
  enum `top|bottom|right|below`). The `{g}` shorthand now aliases
  `{diagrams}` per spec.

### Parser / scanner

* `+` accepted as an augmented quality marker (spec alternate for
  `aug`). `C+` now parses as `quality: '+'` rather than
  `extensions: ['+']`.
* `\u{X+}` brace-form unicode escape (1+ hex digits, surrogates
  recombined) added in ChordPro 6.060, alongside the existing
  `\uXXXX` 4-digit form.
* Empty `[]`, whitespace-only `[ ]+`, and pipe `[|]` chord brackets
  are recognised per ChordPro 6.020/6.080 emergency rules:
  whitespace-only and pipe become `AnnotationToken`s; empty `[]` is
  a zero-width placeholder (no token emitted).
* Auto-generated metadata names (`_key`, `key.print`, `key.sound`,
  `today`, `songindex`, `chordpro.version`, …) are reserved — user
  `{meta:}` cannot collide.
* `{define}` fret values now accept `-1` (ChordPro 6.060) and `N`
  (in addition to `x`/`X`/`-`).
* Bracketed `{define: [Name] …}` form parses as transposable
  (attributes discarded per spec).

### Reference

Verified against `lib/ChordPro/Song.pm` and
`lib/ChordPro/Chords/Transpose.pm` at `ChordPro/chordpro` HEAD plus
the upstream `Changes` file through 6.101 (2026-04-30).

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
