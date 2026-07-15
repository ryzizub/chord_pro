## 0.6.2

### Breaking

* `InlineToken` is a `sealed class`. Adding `ChordRecallToken` to its
  hierarchy is a breaking change for any code with an exhaustive `switch`
  on `InlineToken` subtypes. Add a `ChordRecallToken` case (or a wildcard
  `_` fallback) to fix.

### New

* `ChordRecallToken` — new `InlineToken` subtype emitted when the tokenizer
  encounters `[^]`, the chord-recall operator introduced in ChordPro 6.070
  (experimental). Renderers should advance the active chord-change set (`cc`)
  cursor when they encounter this token.
  Spec: <https://www.chordpro.org/chordpro/ChordChanges/>
* `notesMode` parameter on `Chord.tryParse`, `tokenizeInline`, `assemble`,
  `ChordPro.parse`, and `ChordPro.parseSong` — when `true`, lowercase `a`–`g`
  are accepted as letter-system chord roots, mirroring the `settings.notes`
  ChordPro configuration option. Defaults to `false`; no behaviour change for
  existing call sites. Transposition of notes-mode roots is supported through
  the same chromatic table as uppercase roots.
* `strict` parameter on `ChordPro.parse` and `ChordPro.parseSong` (and the
  internal `assemble`) — when `true`, a `DiagnosticSeverity.warning` is
  emitted for each song that lacks a `{key}` directive, mirroring the
  `settings.strict` ChordPro configuration option. Defaults to `false`,
  consistent with the ChordPro 6.100 change that made forgiving the built-in
  default.

---

## 0.6.1

Maintenance release: adds the `grille` delegated environment and corrects
the legacy `{no_grid}` / `{ng}` directives. No breaking changes.

### New

* `SectionKind.grille` — recognises `{start_of_grille}` / `{end_of_grille}` as
  the experimental `Grille.pm` delegated environment from the reference
  implementation. Previously these fell through to `SectionKind.custom`
  (non-verbatim); they are now captured verbatim, consistent with other
  delegated environments (`abc`, `ly`, `svg`, `textblock`).
  Spec: <https://www.chordpro.org/chordpro/directives-env_grille/>

### Fixed

* Legacy `{no_grid}` / `{ng}` now disable chord diagrams (equivalent to
  `{diagrams: off}`), matching their `{diagrams}` / `{g}` counterparts.
  Previously they fell through to the generic directive path, leaving
  `Song.diagrams` unset. Both forms remain in the lossless
  `Song.directives` stream.

---

## 0.6.0

Final ChordPro 6 spec-parity pass: fills the parser-implementable gaps
left by 0.5.0's audit. Surface changes are mostly additive; a handful of
multi-valued metadata fields move from scalar to list to match the spec.

### Breaking

* `Metadata.sortTitle` / `Metadata.sortArtist` → `Metadata.sortTitles` /
  `Metadata.sortArtists` (lists). One sort entry per `title` / `artist`
  in matching source order per `directives-sorttitle/` and
  `directives-sortartist/`. The old scalar names remain as convenience
  getters returning the first entry.
* `Metadata.key` / `Metadata.time` / `Metadata.tempo` →
  `Metadata.keys` / `Metadata.times` / `Metadata.tempos` (lists). Each
  declaration applies from its position onward per `directives-key/`,
  `directives-time/`, `directives-tempo/`. The scalar names remain as
  convenience getters for the first (primary) declaration.

### New

* `ChordPro.parse` / `parseSong` accept an `altBrackets` argument that
  rewrites a configured two-character pair (e.g. `«»`) to `[` / `]`
  before parsing. Mirrors the `parser.altbrackets` configuration option.
* `GridAttributes.ccName` and `.ccProgression` decode the ChordPro 6.070
  `cc="Name"` / `cc="Name:C1 C2 …"` forms into a typed name plus chord
  list. The raw `cc` string is still surfaced verbatim.
* `ImageDirective` accepts `trbl=` as a synonym for `bordertrbl=`
  (both names appear in the official docs).
* `{define}` / `{chord}` accept `base_fret` (underscore) as a synonym
  for `base-fret` per `directives-define/`.
* Falsy keyword set for `toc=`, `omit=`, … now covers the full
  `key_value_pairs/` list: `0`, `false`, `null`, `no`, `none`, `off`,
  plus the empty string.
* Reserved metadata namespace extended to cover the full
  `chordpro-configuration-format-strings/` list: `page`, `pageno`,
  `pages`, `pagerange`, `instrument`, `instrument.type`,
  `instrument.description`, `tuning`, `user`, `user.name`,
  `user.fullname`.

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
