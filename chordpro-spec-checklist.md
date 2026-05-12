# ChordPro 6 Spec Checklist

> **Spec target:** ChordPro reference implementation **6.101** (released 2026-04-30 — most recent at the time of writing).
> **File-format scope cut-off:** ChordPro 6.100 (released 2026-04-21). 6.101 is a housekeeping release (license + runtime fixes) with no file-format additions.
> **Audited passes:** three independent passes against <https://www.chordpro.org/chordpro/> (see §17). When ChordPro publishes a new release, refresh this banner and re-run the audit suite (`test/spec_audit_test.dart`).

Ground-truth checklist of every directive, shorthand, grammar rule, and token in the ChordPro 6 file format, distilled from <https://www.chordpro.org/chordpro/>. Each item is one parser/feature obligation. **Don't edit casually.** This file is the audit baseline; the implementation should be checked against it, not the other way around.

Sources used (all under `https://www.chordpro.org/chordpro/`):

- `chordpro-introduction/`
- `chordpro-directives/`
- `chordpro-chords/`
- `chordpro-cheat_sheet/`
- `chordpro6-relnotes/`
- `chordpro-version-history/`
- `chordpro-reference-relnotes/` (per-version 6.000–6.101)
- `chordpro-markup/`
- `chordpro-symbols/`
- `chordpro-colours/`
- `chords-over-lyrics/`
- `directives-new_song/`, `directives-title/`, `directives-sorttitle/`, `directives-subtitle/`, `directives-artist/`, `directives-sortartist/`, `directives-composer/`, `directives-lyricist/`, `directives-arranger/`, `directives-copyright/`, `directives-album/`, `directives-year/`, `directives-key/`, `directives-time/`, `directives-tempo/`, `directives-duration/`, `directives-capo/`, `directives-tag/`, `directives-meta/`
- `directives-comment/`, `directives-image/`
- `directives-env/`, `directives-env_chorus/`, `directives-env_verse/`, `directives-env_bridge/`, `directives-env_tab/`, `directives-env_grid/`, `directives-env_textblock/`
- `directives-delegates/`, `directives-env_abc/`, `directives-env_ly/`, `directives-env_svg/`
- `directives-define/`, `directives-chord/`, `directives-transpose/`
- `directives-titles_legacy/`, `directives-diagrams/`, `directives-columns/`, `directives-pagetype_legacy/`, `directives-new_page/`, `directives-new_physical_page/`, `directives-column_break/`
- `directives-props_chord_legacy/` (and the parallel `props_*_legacy` pages)
- `key_value_pairs/`
- `chordpro-configuration-parser/`
- `chordpro-configuration-format-strings/`
- `keys_and_transpositions/`
- `directives-custom/`
- `chordpro-fonts/`
- `chordchanges/`
- `directives-chorus/`
- `directives-sorttitle/`

Legend:

- `[ ]` = parser obligation / spec rule. Audit should mark `[x]` when the implementation handles it (and link the test).
- `since:` = version that introduced the feature (per release notes / cheat sheet).
- `verbatim:` = line copied directly from the spec.

---

## 1. Source-level grammar (lexer / scanner)

### 1.1 File structure

- [ ] File is a sequence of lines. A line is one of: lyrics-and-chords line, directive line, comment line, empty line. (intro, verbatim: "Lyrics-and-chords lines / Directive lines / Comment lines (starting with `#`) / Empty lines (permitted)")
- [ ] Recognised file extensions: `.cho`, `.crd`, `.chopro`, `.chord`, `.pro`. (intro)
- [ ] A file may contain multiple songs. Songs are delimited by `{new_song}` / `{ns}`. (intro, see §6.1)

### 1.2 Encoding

- [ ] Accept ASCII, ISO 8859-1, UTF-8, UTF-16, UTF-32. (cheat_sheet)

### 1.3 File-level comments

- [ ] Lines starting with `#` (file-level only — not mid-line) are dropped. (intro: "Lines starting with `#` are ignored … only relevant for maintainers")

### 1.4 Line continuation

- [ ] Trailing `\` at end of line continues onto next line. (cheat_sheet, since 6.010, verbatim release-note: "Allow line continuation using backslash")

### 1.5 Unicode escapes

- [ ] `\u` followed by exactly 4 hex digits is a Unicode escape. (cheat_sheet, since 6.010)
- [ ] Brace form `\u{X+}` (1+ hex digits) supports surrogate-pair / extended characters. (since 6.060, verbatim release-note: "Handle Unicode escapes for surrogates and extended characters (\u{…})")

### 1.6 Backslash escapes inside lyrics

- [ ] Spec is silent on per-character escapes (`\[`, `\]`, `\{`, `\}`, `\\`) inside lyric text. README marks these as a non-spec extension of this Dart parser.

### 1.7 Bracket / brace tokens

- [ ] `[` … `]` is a chord bracket. (intro)
- [ ] `[*` … `]` is an annotation bracket. (intro: "textual remarks placed above the lyrics, just like chords"; cheat_sheet)
- [ ] `{` … `}` is a directive. (intro)
- [ ] Spec assumes a directive occupies its own line (intro: "Directive lines"). README marks mid-lyric `{…}` as a parser-specific lenience.
- [ ] Directive parser closes on first unescaped `}`. Attribute values cannot contain a literal `}`.

### 1.8 Key/value semantics (key_value_pairs)

Common rules used across attribute parsing:

- [ ] Falsy keyword set: `0`, `false`, `null`, `no`, `none`, `off`, plus the empty string. (key_value_pairs)
- [ ] Truthy keyword set: `1`, `true`, `on`, plus any non-falsy non-empty value. (key_value_pairs)
- [ ] Numeric attribute values may carry a unit suffix: `%`, `em`, `ex`, `pt`, `px`, `in`, `cm`, `mm`. Default unit is points. (key_value_pairs)

### 1.9 Alternate chord brackets (configuration)

- [ ] `parser.altbrackets` configuration accepts a two-character pair (e.g. `«»`). When set, those characters are treated as chord brackets and replaced by `[` / `]` after analysis. (chordpro-configuration-parser)

### 1.10 Source preprocessor (`parser.preprocess`, since 6.010, experimental)

Configurable line-level rewrite stage that runs **before** chord/directive parsing. (chordpro-configuration-parser)

- [ ] `parser.preprocess.all` — array of rewrite items applied to every line.
- [ ] `parser.preprocess.directive` — array applied only to directive lines.
- [ ] `parser.preprocess.songline` — array applied only to lyric lines.
- [ ] `parser.preprocess.env-<name>` — array scoped to a specific environment (e.g. `parser.preprocess.env-tab`).
- [ ] Rewrite item shape:
  - [ ] `target` — exact-string match (one of `target` or `pattern` is required).
  - [ ] `pattern` — regular expression (one of `target` or `pattern` is required).
  - [ ] `replace` — replacement string.
  - [ ] `flags` — regex flags string; default `g`.
  - [ ] `select` — optional condition gating when the rewrite applies.

### 1.11 Settings that affect parsing / chord grammar

Configuration keys that change accepted input or default behaviour:

- [ ] `settings.notes` — opt-in to **notes mode** (lowercase note names accepted as chords; no diagram support). (chordpro-chords; relnotes 0.978)
- [ ] `settings.strict` — when true, rejects unknown chord extensions; default flipped to **false** in 6.100. (relnotes 6.100)
- [ ] `settings.wraplines` — controls line wrapping; default `true`. (since 6.100, relnotes)
- [ ] `settings.choruslabels` — when `false`, the label argument of `{chorus}` replaces the standard "Chorus" header text instead of labelling the recall. (directives-chorus; see §6.3)
- [ ] `settings.maj7delta` — when set, renders `maj7` as the delta symbol instead of "maj7". (relnotes 6.080)
- [ ] `keys.flats` — when true, prefers flat enharmonics on transpose. (since 6.100)
- [ ] `keys.force-common` — when true, enforces ≤5 accidentals in transposed keys. (since 6.100)

---

## 2. Chord grammar

Order of components inside `[ ]`: **root → qualifier → extension → bass-slash**. (chordpro-chords)

### 2.1 Roots

- [ ] Latin letters: `A B C D E F G`. (chordpro-chords)
- [ ] German `H` for B-natural. (chordpro-chords; README marks as common extension but the spec page lists it under "Pitch letters: A, B, C, …, G (European/Dutch), H (German)")
- [ ] Roman numerals: `I II III IV V VI VII`. (chordpro-chords)
- [ ] Nashville numbers: `1 2 3 4 5 6 7`. (chordpro-chords)

### 2.2 Accidentals

- [ ] `#` (sharp), `b` (flat). (chordpro-chords)
- [ ] Unicode `♯` (U+266F), `♭` (U+266D) — README extension (parser must accept).

### 2.3 Quality / qualifier tokens

- [ ] Minor: `m`, `mi`, `min`, `-`. (`mi` allowed as shorthand for `min` since 6.070 release notes)
- [ ] Major: `maj`, `^`. (chordpro-chords)
- [ ] Diminished: `dim`, `0`. (chordpro-chords)
- [ ] Half-diminished: `h`. (chordpro-chords)
- [ ] Augmented: `aug`, `+`. (chordpro-chords)

### 2.4 Suspensions / additions

- [ ] `sus`, `sus2`, `sus4`, `sus9`. (chordpro-chords)
- [ ] `add`, `add2`, `add4`, `add9`. (chordpro-chords)

### 2.5 Numeric extensions

- [ ] Numbers: `2 3 4 5 6 7 9 11 13`. (chordpro-chords)
- [ ] Combined `69` (= 6/9 chord). (chordpro-chords)
- [ ] `alt`. (chordpro-chords)

### 2.6 Alterations

- [ ] `b5`, `#5`, `b9`, `#9`, `b13`, `#11`, etc. — flat/sharp prefixed to interval number. (chordpro-chords)

### 2.7 Bass slash

- [ ] `/` followed by bass note: `C/B`, `Am/G`. (chordpro-chords)

### 2.8 Annotations

- [ ] `[*text]` — annotation, "textual remarks placed above the lyrics, just like chords". (intro; chordpro-chords; since 6.0)
- [ ] Annotation text is free-form (not parsed as a chord).

### 2.9 Bracket recovery / pseudo-chords (ChordPro 6.020 / 6.080)

- [ ] `[ ]+` (whitespace inside brackets) parses as an annotation. (6.020 release note: "Turn pseudo-chords like `|` and spaces into annotations")
- [ ] `[|]` pipe-only parses as an annotation. (6.020 release note, same line)
- [ ] Empty `[]` is a valid token (zero-width placeholder). (6.080 release note: "Emergency chord brackets in lyrics and annotations available")

### 2.10 No-chord marker

- [ ] `NC`, `N.C.`, `N.C` — README extension; spec is silent (6.070 release note tweaked NC handling: "Changed NC (no chord) handling (issue #441)"). Parser should tolerate it; rendering treats as no chord.

### 2.11 Parsing modes

- [ ] Strict mode rejects unknown extensions; relaxed mode permits custom extensions. (chordpro-chords)
- [ ] Notes mode: lowercase note names (e.g. `do`, `re`, `mi` for solfège, or lowercase letter forms) treated as chords without diagram support. Requires `settings.notes` configuration. (chordpro-chords; 0.978 relnotes: "Alternative note naming systems (Latin, Solfege)")

### 2.12 Markup inside chord brackets

- [ ] Pango markup may wrap a chord, e.g. `[<span color="red">Daug</span>]`. (markup)
- [ ] Markup must NOT split the chord name across spans, e.g. `[<span>D<sup>aug</sup></span>]` is invalid. (markup)
- [ ] Marked-up chords appear as separate entries in chord diagrams. (markup)
- [ ] Simple markup in chords allowed since 6.010. (release-note, verbatim: "Allow simple markup in chords (including grid chords)")

### 2.13 Chord-over-lyric placement

- [ ] Chord precedes the syllable it belongs to. (intro: "Chords are 'placed in front of the syllable they belong to'")
- [ ] Output renders the chord above the syllable. (intro)
- [ ] Multiple chords on a syllable / trailing chord rules: spec page does not formalise; treat as concatenation.

---

## 3. Directives — preamble

### 3.1 `{new_song}` / `{ns}` (since 1.0)

- [ ] Marks song boundary. (directives-new_song, verbatim: "indicates that the current song, if any, is complete and that a new song will follow")
- [ ] Attribute `toc=` with values `no` / `false` / `0` suppresses song from table of contents. (directives-new_song; 6.040 release: "Suppress table of content entry with `{ns toc=no}`")

---

## 4. Directives — metadata

All metadata directives have an equivalent `{meta: name value}` form. (directives-meta, cheat_sheet)

`{meta}` rules:

- [ ] Form: `{meta: name value}`. (directives-meta)
- [ ] `name` must be a single word; underscores allowed. (directives-meta, verbatim: "name must be a single word but may include underscores")
- [ ] Repeating a `{meta: name v}` adds another value (multi-valued). (directives-meta, verbatim: "Multiple values can be set by multiple meta-directives")
- [ ] Custom names are free-form; lowercase single words advised. (directives-meta)
- [ ] `arranger` directive exists in addition to the cheat-sheet list. (directives-arranger, README confirms)

| Directive | Short | Value | Notes / since |
|---|---|---|---|
| [ ] `title` | `t` | text | since 1.0 |
| [ ] `sorttitle` | — | text | since 6.0 |
| [ ] `subtitle` | `st` | text | since 1.0 |
| [ ] `artist` | — | text | since 5.0 |
| [ ] `sortartist` | — | text | since 6.080 |
| [ ] `composer` | — | text | since 5.0 |
| [ ] `lyricist` | — | text | since 5.0 |
| [ ] `arranger` | — | text | multi-valued (directives-arranger) |
| [ ] `copyright` | — | text | since 5.0 |
| [ ] `album` | — | text | since 5.0 |
| [ ] `year` | — | text/number | since 5.0 |
| [ ] `key` | — | key string (e.g. `C`, `Am`, etc.) | since 5.0; multi-valued (each applies from its position onward, per directives-key); mode/Nashville/Roman not formalised |
| [ ] `time` | — | `n/m` time signature | since 5.0; multi-valued (each from its position onward) |
| [ ] `tempo` | — | integer BPM | since 5.0; multi-valued |
| [ ] `duration` | — | integer seconds OR `mm:ss` | since 5.0; always shown in mm:ss form |
| [ ] `capo` | — | integer fret | since 5.0 |
| [ ] `tag` | — | text | since 6.080; multi-valued |
| [ ] `meta` | — | `name value` (see rules above) | since 5.0 |

Auto-generated / reserved metadata. Spec lists the names; the silent-drop on user `{meta:}` collision is an **implementation choice** (not a spec rule) — this parser drops them so renderers see only their own derived values.

Key/transpose:

- [ ] `_key` — auto, **capo-adjusted** key (the key as it sounds when the capo value is applied; not the same as `key_actual`). (directives-key)
- [ ] `key.print` — possibly-transposed key, intended for display. **(since 6.100, keys_and_transpositions)**
- [ ] `key.sound` — sounding key after capo adjustment. **(since 6.100, keys_and_transpositions)**
- [ ] `key_actual` — auto, **transpose-adjusted** key (driven by `{transpose}`, not capo). (directives-transpose) **DEPRECATED in 6.100** — keys_and_transpositions/ states `key_actual`/`key_from` were "removed as being misleading and not useful"; replaced by `key.print` / `key.sound`. (Note: `directives-transpose/` and `chordpro-configuration-format-strings/` still document them on the live site — pre-6.100 documentation lag.)
- [ ] `key_from` — auto, original key prior to `{transpose}`. (directives-transpose) **DEPRECATED in 6.100** — same source as `key_actual` above.

Runtime / build:

- [ ] `chordpro`, `chordpro.version`, `chordpro.songsource` — auto runtime metadata. (6.060 release note)
- [ ] `today` — current date at render time; format is **configurable** (output configuration controls the date pattern, not fixed by the spec). (chordpro-configuration-format-strings)

Layout / page:

- [ ] `page` (= `pageno`), `pages` — current and total page numbers. (chordpro-configuration-format-strings)
- [ ] `page.class` (`first`, `title`, `default`), `page.side` (`left`, `right`) — auto layout metadata. (6.070 release note)
- [ ] `pagerange` — page range string (CSV output only). (chordpro-configuration-format-strings)

Song / index / chord stats:

- [ ] `songindex` — 1-based index of the song in the document. (chordpro-configuration-format-strings)
- [ ] `chords`, `numchords` — chord list / count for the song. (chordpro-configuration-format-strings)

Instrument / user:

- [ ] `instrument`, `instrument.type`, `instrument.description` — selected instrument. (chordpro-configuration-format-strings)
- [ ] `tuning` — instrument tuning. (chordpro-configuration-format-strings)
- [ ] `user`, `user.name`, `user.fullname` — running user identity. (chordpro-configuration-format-strings)

Bookmarks:

- [ ] `bookmark` — used by `{meta: bookmark <id>}` to set a named bookmark. (markup)

Format-string substitutions:

- [ ] `%{name}` — straight substitution. (define page; 6.070 release: "Allow '%{}' substitutions in grid sections")
- [ ] All reserved-namespace items above are also valid `%{…}` substitution keys.
- [ ] `%{name|true-text|false-text}` — truthiness branch on `name`. (chordpro-configuration-format-strings)
- [ ] `%{name|true-text}` — single-branch (emits `true-text` when `name` is truthy, empty otherwise).
- [ ] `%{name=value|true-text|false-text}` — equality test on `name`.
- [ ] `%{}` — value of the controlling item in the enclosing context.
- [ ] Backslash-escape `\`, `{`, `}`, `|` inside format strings to use them literally.

Multi-valued metadata invariants:

- [ ] `sortartist` requires one entry per `artist`, in matching source order, when multiple artists are present. (directives-sortartist, verbatim: "If a song has multiple artists, there must be a `sortartist` for each `artist`, and in the same order.")
- [ ] `sorttitle` requires one entry per `title`, in matching source order, when multiple titles are present. (directives-sorttitle, verbatim: "there must be a `sorttitle` for each `title`, and in the same order")

---

## 5. Directives — comments / highlight (formatting)

### 5.1 `{comment}` / `{c}` (since 1.0)

- [ ] Inline-flow comment line. (directives-comment, verbatim: "introduce a _comment_ line, a piece of text that will be included in the printed output but is not part of the lyrics and chords")
- [ ] Historically rendered with grey background. (directives-comment)

### 5.2 `{comment_italic}` / `{ci}` (since 3.6)

- [ ] Inline-flow italic comment. (directives-comment)

### 5.3 `{comment_box}` / `{cb}` (since 3.6)

- [ ] Inline-flow boxed comment. (directives-comment)
- [ ] Note: cheat sheet lists `{cb}` as both `comment_box` and `column_break`. The full forms disambiguate.

### 5.4 `{highlight}` (since 5.0)

- [ ] "Same as comment". (cheat_sheet, directives-comment)

---

## 6. Directives — environments (sections)

### 6.1 General environment rules (directives-env)

- [ ] Pattern: `{start_of_X}` … `{end_of_X}`, each on its own line. (directives-env)
- [ ] `X` may contain letters, digits, underscores. (directives-env)
- [ ] Custom (unknown) environments must be treated as song lyrics. (directives-env, verbatim: "unknown (unhandled) environments should always be treated as part of the song lyrics")
- [ ] Optional label attribute: `label="text"` (preferred) or legacy bare value `{start_of_X: text}`. (directives-env, since 5.1 / 6.0; cheat_sheet: "Section labels available since version 6.0")
- [ ] Multi-line label via `\n`: `label="Verse 1\nAll"`. (directives-env)
- [ ] `{end_of_X}` must NOT carry a conditional selector even when `{start_of_X-sel}` does. (directives — Conditional, verbatim: "the section end must **not** include the selector")

### 6.2 Built-in environments

| Env | Start | End | Short | Body | Since |
|---|---|---|---|---|---|
| [ ] verse | `start_of_verse` | `end_of_verse` | `sov`/`eov` | structured | 6.0 |
| [ ] chorus | `start_of_chorus` | `end_of_chorus` | `soc`/`eoc` | structured | 1.0 |
| [ ] bridge | `start_of_bridge` | `end_of_bridge` | `sob`/`eob` | structured | 6.0 |
| [ ] tab | `start_of_tab` | `end_of_tab` | `sot`/`eot` | **verbatim** (no folding/markup; only `{end_of_tab}`/`{eot}` interpreted) | 3.6 |
| [ ] grid | `start_of_grid` | `end_of_grid` | `sog`/`eog` | grid tokens | 5.0 (sog/eog short-forms added 6.060) |

### 6.3 `{chorus}` recall (since 5.0)

- [ ] Bare `{chorus}` plays the most recently defined chorus. (env_chorus)
- [ ] `{chorus: Final}` — legacy bare-label form. (env_chorus)
- [ ] `{chorus label="Final"}` — attribute form. (6.060 release: "Allow `label="…"` for `{chorus}` and `{grid}`")
- [ ] `{chorus: label="Final"}` — colon + attribute form (README states all four spec forms must parse).
- [ ] `settings.choruslabels` (default `true`): when `false`, the label argument **replaces** the standard "Chorus" header text instead of labelling a recalled chorus section. (directives-chorus)

### 6.4 `{start_of_grid}` body (env_grid)

Attributes:

- [ ] `shape="cells"` (e.g. `"4"`).
- [ ] `shape="measuresxbeats"` (e.g. `"4x4"`).
- [ ] `shape` with margins: `"left+cells+right"` or `"left+measuresxbeats+right"` — either margin optional; default `"1+4x4+1"`.
- [ ] Legacy bare-shape form: `{start_of_grid: shape}` (no other attrs allowed in this form).
- [ ] `label="text"`.
- [ ] `cc` (chord-changes) attribute (since 6.070, experimental; chordchanges):
  - [ ] `cc="Name"` — declares a named chord-change set scoped to the section.
  - [ ] `cc="Name:C1 C2 …"` — combined name + predefined chord progression.
  - [ ] In lyric / grid bodies the bracket token `[^]` recalls the next chord from the active `cc` set, advancing the cursor by one. (chordchanges, since 6.070)

Grid body tokens (whitespace-separated):

- [ ] Chord symbols.
- [ ] `.` empty cell.
- [ ] `/` "play chord here" placeholder.
- [ ] `~` separator for multiple chords in one cell.
- [ ] Bar symbols: `|`, `||`, `|.`, `|:`, `:|`, `:|:`.
- [ ] Volta markers: `|1`, `|2`, `:|1`, `:|2`, `:|2>`.
- [ ] Repeat shorthand: `%` (repeat last measure), `%%` (repeat last two measures).
- [ ] Strum-line indicator after first bar: `S` (show bars/lines), `s` (omit). (since 6.080)
- [ ] Strum pseudo-chords: up `u`, `up`, `u+`, `ua`, `ua+`, `ux`, `ux+`, `us`, `us+`; down `d`, `dn`, `d+`, `da`, `da+`, `dx`, `dx+`, `ds`, `ds+`; muted `x`. (since 6.080)

### 6.5 Delegated environments (directives-delegates)

Common rules:

- [ ] Body captured verbatim and passed to a delegate.
- [ ] Output is normally an image; delegate may set `type=omit` or `type=none` in config.
- [ ] Delegated envs share image-directive attributes (e.g. `label`, `align`, `id`, `width`, `height`, `scale`, `center`, `omit`, anchor-related attrs). (env_textblock, env_abc, env_svg)

| Env | Body rules | Notes / since |
|---|---|---|
| [ ] `start_of_abc`/`end_of_abc` | First line `X:1`; must contain `K:`; insert blank line before close. Renders to SVG. | label, align, `split` (default on since 6.030; `split="0"` disables), `staffsep`. ChordPro `{transpose}` **DOES** cascade into the embedded ABC (per directives-env_abc). For ABC-only transposition independent of ChordPro, use the ABC `%%transpose` directive. |
| [ ] `start_of_ly`/`end_of_ly` | Body must start with a line beginning `%` or `\`. Lines before that are **body-prefix formatting instruction lines** — `scale=n` and `center` are body lines, not directive attributes. `\version` and `\header { tagline = ##f }` auto-prepended. | Directive attribute: `label` only. `{transpose}` does NOT cascade. |
| [ ] `start_of_svg`/`end_of_svg` | Body is valid SVG/XML. | Same image-style attrs. |
| [ ] `start_of_textblock`/`end_of_textblock` | Body is text formatted into a placeable image. | Since 6.050. See §6.6. |

### 6.6 Textblock attributes (since 6.050)

Textblock-specific:

- [ ] `width="n"` — only larger than tight fit.
- [ ] `height="n"` — only larger than tight fit; setting it (alongside or instead of `padding=`) triggers tight-fit mode. (directives-env_textblock, verbatim: "tight fit applies when height or padding is set")
- [ ] `padding="n"` — triggers tight-fit mode.
- [ ] `flush="left|center|right"` — horizontal flush.
- [ ] `vflush="top|middle|bottom"` — vertical flush.
- [ ] `textstyle="<style>"` — style name from config (default `text`).
- [ ] `textsize="n"` — accepts numeric, `%`, `em`, `ex`.
- [ ] `textspacing="n|flex"` — fraction of font size, or `flex` for natural height.
- [ ] `textcolor="<colour>"`.
- [ ] `background="<colour>"`.
- [ ] `omit="bool"` — when true, delegate ignored.

Inherited from `{image}` directive: see §10.

### 6.7 Custom environments

- [ ] `{start_of_<name>}` / `{end_of_<name>}` with arbitrary `<name>` (letters/digits/underscores) preserved as a custom section. (directives-env)
- [ ] Same `label="…"` attribute support and legacy bare-label form.

---

## 7. Conditional directives (selectors)

Verbatim from `chordpro-directives/`:

> "All directives can be conditionally selected by postfixing the directive with a dash (hyphen) and a _selector_."
>
> "If a selector is used, ChordPro first tries to match it with the instrument type … If this fails, it tries to match it with the user name … Finally, it will try it as a meta item, selection will succeed if this item exists and has a 'true' value (i.e., not empty, zero, `false` or `null`). Selection can be reversed by appending a `!` to the selector."
>
> "Note that the section end must **not** include the selector."

- [ ] Postfix syntax: `{name-sel: …}`.
- [ ] Negation: `{name-sel!: …}` (selector immediately followed by `!`, before the colon).
- [ ] Match order: instrument type → user name → metadata truthiness. Falsy = empty / `0` / `false` / `null`.
- [ ] Matching is case-insensitive (README confirms; spec page does not contradict).
- [ ] Section start may be selected; section END must use the unselected form.
- [ ] Spec lists the rule once and applies it to ALL directives; in practice the parser must gate (at minimum): metadata, formatting, sections (start_of_*), comments, images, layout breaks, chord recalls (`{chorus}`), and chord definitions (`{define}`/`{chord}`).
- [ ] README marks legacy alt forms `{name-!sel}` and `{name+sel}` as non-spec parser leniencies — new files must use the spec `name-sel!` form.

Examples (verbatim):

```
{define-guitar:  Am base-fret 1 frets 0 2 2 1 0 0}
{define-ukulele: Am base-fret 1 frets 2 0 0 0}
{comment-alto:   Very softly!}
{comment-tenor:  Sing this with power}
{start_of_verse-soprano} ... {end_of_verse}
```

---

## 8. Chord definitions

### 8.1 `{define}` (since 1.0; sub-attrs since 6.0)

Forms:

```
{define: name base-fret offset frets pos pos … pos}
{define: name base-fret offset frets pos pos … pos fingers pos pos … pos}
{define: name keys note … note}
{define: A copy B …}
{define: A copyall B …}
{define: A display C …}
{define: …  diagram on|off|<colour> …}
{define: …  format <fmt> …}
{define: [Name] …}
```

Attributes:

- [ ] `base-fret <n>` — integer ≥ 1; topmost finger position.
- [ ] `frets <p1> … <pN>` — values: integer, `0` (open), `-1` / `x` / `N` (muted), `1`–`9`. Six positions for default 6-string (left → right = lowest → highest string).
- [ ] `fingers <p1> … <pN>` — 1–9 or A–Z; positions for open/muted ignored; same length as frets.
- [ ] `keys <k1> … <kN>` — semitone intervals from root for keyboards (0=root, 4=major3rd, 7=fifth, 11=dom7, 12=octave, …).
- [ ] `copy <name>` — duplicate diagram of an existing chord.
- [ ] `copyall <name>` — copy diagram + display + format.
- [ ] `display <name>` — overrides displayed name in output.
- [ ] `diagram on|off|<colour>` — visibility / colour.
- [ ] `format <fmt>` — format string with `\%{…}` substitutions (escape `%` as `\%` to defer substitution). README notes the parser captures format as String but does not interpret it.
- [ ] `format` substitution variables (chordpro-configuration-format-strings):
  - [ ] `%{name}` — full chord name as written.
  - [ ] `%{root}` — root note.
  - [ ] `%{qual}` — quality (`m`, `maj`, `dim`, …).
  - [ ] `%{ext}` — extension (`7`, `b9`, …).
  - [ ] `%{bass}` — bass note for slash chords.
  - [ ] `%{xp.root}`, `%{xp.qual}`, `%{xp.ext}`, `%{xp.bass}` — transposed forms.
  - [ ] `%{xc.root}`, `%{xc.qual}`, `%{xc.ext}`, `%{xc.bass}` — transcoded forms.
  - [ ] `%{xc.formatted}` — formatted pre-transcoding chord name (rendered string for the original chord). (chordpro-configuration-format-strings)
- [ ] Bracketed `[Name]` form — enables transposition / transcoding of the definition. (since 6.100)
- [ ] Both `base-fret` (hyphen) and `base_fret` (underscore) appear on directives-define/. Robust parsers should accept both spellings. (see §16)

### 8.2 `{chord}` (since 5.0)

Forms (env_chord):

```
{chord: name}
{chord: [name]}
{chord: name base-fret offset frets pos pos … pos}
{chord: name base-fret offset frets pos pos … pos fingers pos pos … pos}
```

Rules:

- [ ] "similar to define but it only displays the chord immediately in the song where the directive occurs." (directives-chord, verbatim)
- [ ] Default not transposed/transcoded.
- [ ] `[name]` brackets enable transposition; when bracketed, no other attributes allowed.
- [ ] `{chord}` accepts the full `{define}` attribute set: `base-fret`, `frets`, `fingers`, `keys`, `copy`, `copyall`, `display`, `diagram`, `format`. (directives-chord, verbatim: "accepts all the same arguments as `{define}`")

### 8.3 `{transpose}` (since 5.0)

- [ ] `{transpose: <semitones>}` — positive uses sharps, negative uses flats by default. (directives-transpose)
- [ ] `{transpose}` (no value) — cancels current transposition, restoring previous. (directives-transpose)
- [ ] Modifier `s` — force sharps regardless of sign (e.g. `{transpose: -10s}`).
- [ ] Modifier `f` — force flats regardless of sign (e.g. `{transpose: 2f}`).
- [ ] Modifier `k` — follow the song's `{key}` for enharmonic preference. (keys_and_transpositions; added in 6.100 as part of the keys-and-transpositions rework)
- [ ] At song start: transposes whole song. Mid-song: modulates from that point on.
- [ ] Does NOT retroactively modify preceding `{key}` directives.
- [ ] Adds metadata `key_actual` (transposed) and `key_from` (original).
- [ ] README notes parser additionally tolerates `#`/`b`/`♯`/`♭` glyph aliases for the `s`/`f` qualifiers as a non-spec leniency.

---

## 9. Formatting directives — fonts / sizes / colours

Common shape: `{<name>: <value>}` with empty value `{<name>}` resetting. (props_*_legacy pages)

Value rules:

- [ ] `*font` — one of: (a) a built-in font name, (b) a path to a TTF/OTF file, or (c) a description string `"family [style] [weight] [size]"` (e.g. `"arial bold 14"`). (chordpro-fonts)
- [ ] `*size` — number (`12`, `10.5`) or percentage (`120%`). (props_chord_legacy)
- [ ] `*colour` — known colour name OR `#RRGGBB`. (props_chord_legacy)
- [ ] American spelling `color` accepted as synonym (README confirms; in practice the spec uses British `colour`).

Recognised colour names (chordpro-colours): `red`, `green`, `blue`, `yellow`, `magenta`, `cyan`, `black`, `white`. Hex form: `#RRGGBB` (e.g. `#4419ff`).

Built-in font aliases (chordpro-fonts):

- [ ] `sans-serif` ⇄ `sans`.
- [ ] `monospace` ⇄ `mono`.
- [ ] `muse` ⇄ `musejazztext`.
- [ ] Legacy PostScript family names are soft aliases for `mono` / `sans` / `serif`. Exact accepted spellings (chordpro-fonts):
  - [ ] Courier family: `Courier`, `Courier-Bold`, `Courier-Oblique`, `Courier-BoldOblique` → `mono`.
  - [ ] Helvetica family: `Helvetica`, `Helvetica-Bold`, `Helvetica-Oblique`, `Helvetica-BoldOblique` → `sans`.
  - [ ] Times family: `Times-Roman`, `Times-Bold`, `Times-Italic`, `Times-BoldItalic` → `serif`.

Directive families:

| Directive | Short | Since |
|---|---|---|
| [ ] `chordfont` / `chordsize` / `chordcolour` | `cf` / `cs` / — | 1.0 / 1.0 / 5.0 |
| [ ] `textfont` / `textsize` / `textcolour` | `tf` / `ts` / — | 1.0 / 1.0 / 5.0 |
| [ ] `chorusfont` / `chorussize` / `choruscolour` | — | 6.030 |
| [ ] `tabfont` / `tabsize` / `tabcolour` | — | 5.0 |
| [ ] `gridfont` / `gridsize` / `gridcolour` | — | 5.0 |
| [ ] `tocfont` / `tocsize` / `toccolour` | — | 5.0 |
| [ ] `titlefont` / `titlesize` / `titlecolour` | — | 5.0 |
| [ ] `footerfont` / `footersize` / `footercolour` | — | 5.0 |
| [ ] `labelfont` / `labelsize` / `labelcolour` | — | 6.070 |

---

## 10. Image directive (since 5.0)

Forms:

```
{image: "<filename>"}
{image: src="<filename>" key=value …}
```

Attributes (cheat_sheet + directives-image):

- [ ] `src=<filename>` — image file. PNG/JPG/GIF/ABC/SVG supported.
- [ ] `width=<pts|%>` — desired width.
- [ ] `height=<pts|%>` — desired height.
- [ ] `scale=<factor|%>` — scale factor; supports two comma-separated factors for independent X/Y. (since 6.060)
- [ ] `align=left|center|right` — horizontal alignment (default `center`).
- [ ] `center` / `center=<arg>` — deprecated synonym for `align=center` (`0` flushes left).
- [ ] `border` (default 1pt) and `border=<width>` — border width in points.
- [ ] `bordertrbl=<letters>` (cheat sheet) / `trbl=<letters>` (directives-image) — selective borders: `t` top, `r` right, `b` bottom, `l` left. Both names appear in the official docs; a robust parser should accept either.
- [ ] `title="<text>"` — caption.
- [ ] `label="<text>"` — left-margin label.
- [ ] `href=<url>` — clickable image. (since 6.060)
- [ ] `id=<identifier>` — define a reusable asset; refer back via `id` only. (since 6.010)
- [ ] `x=<pts|%>` — horizontal offset (static images, since 6.010).
- [ ] `y=<pts|%>` — vertical offset (static images, since 6.010).
- [ ] `spread=<advance>` — full-width top placement; shifts content down by image height + `advance`.
- [ ] `anchor=<value>` — placement reference (since 6.010); allowed values:
  - [ ] `paper` — relative to paper boundaries (top-left origin); supports negative offsets and `%`.
  - [ ] `page` — relative to page boundaries (excluding margins); `%` adjusts for image size.
  - [ ] `allpages` — repeats image on every page (experimental, since 6.080).
  - [ ] `column` — accounts for column layout.
  - [ ] `line` — positions relative to lyric line.
  - [ ] `float` — default; placed between lyric lines.

Attributes NOT on the `{image}` directive page (book-keeping):

- [ ] `chord=<chordname>` is an **inline `<img/>`** attribute (see below), not a block `{image}` attribute. (directives-image)
- [ ] `type=<format>` is a **delegate-config** attribute (delegates page), not a block `{image}` attribute.
- [ ] `omit=<bool>` is a **delegate-environment** attribute (textblock / abc / ly / svg) — surfaces on those env start directives, not on block `{image}`.
- [ ] `persist` is README-only — does not appear on directives-image/ or the cheat sheet; treat as a non-spec passthrough.

Inline `<img/>` form:

- [ ] `<img src="…" />`, `<img id="…" />`, `<img chord="…" />`. (markup; since 6.040)
- [ ] Inline-only attributes: `width`, `height`, `dx`, `dy`, `scale`, `align`, `bbox`, `w` (advance width), `h` (advance height).

---

## 11. Output / layout / page directives

| Directive | Short | Value | Notes / since |
|---|---|---|---|
| [ ] `new_page` | `np` | — | start new logical page (3.6) |
| [ ] `new_physical_page` | `npp` | — | force physical page break (3.6) |
| [ ] `column_break` | `cb` (directives-column_break and cheat sheet — same short form as `comment_box`; full names disambiguate) | — | column break (3.6) |
| [ ] `pagetype` | — | `a4`, `letter`, … | legacy; controls paper size (4.0) |
| [ ] `columns` | `col` | integer | number of layout columns (3.6) |
| [ ] `titles` | — | `left`/`center`/`right` | legacy; centre is default (3.6.4) |
| [ ] `diagrams` | — | `on`, `off`, `top`, `bottom` (default), `right`, `below` | replaces obsolete `grid`/`no_grid` (6.020) |
| [ ] `grid` | `g` | (legacy) | obsolete alias for `diagrams` (3.6) |
| [ ] `no_grid` | `ng` | (legacy) | obsolete; equivalent to `diagrams: off` (3.6) |

---

## 12. Custom extensions

- [ ] `x_*` namespace: any directive name starting with `x_` is a custom extension. (cheat_sheet, since 5.0)
- [ ] Spec rule: tools that don't recognise an `x_*` directive **silently ignore** it. (directives-custom, verbatim: "silently ignore unknown custom directives")
- [ ] Future-proofing rule: "The ChordPro file format specification will never define directives that start with `x_`." (directives-custom)
- [ ] **Implementation deviation:** this parser preserves them on `Song.customExtensions` so callers can opt in to processing them. (README extension over spec)

---

## 13. Pango-style markup (lyrics + comments)

### 13.1 Container

- [ ] `<span … />` and paired `<span>…</span>`.

### 13.2 Span attributes (markup)

- [ ] `font_desc` — font description string.
- [ ] `font_family` (synonym `face`) — `normal | sans | serif | monospace` (or family name).
- [ ] `size` — points / `%` / symbolic (`xx-small`, `x-small`, `small`, `medium`, `large`, `x-large`, `xx-large`, `smaller`, `larger`).
- [ ] `style` — `normal | oblique | italic`.
- [ ] `weight` — `normal | bold`.
- [ ] `foreground` — `#RRGGBB` or named.
- [ ] `background`.
- [ ] `underline` — `single | double | none`.
- [ ] `underline_colour`.
- [ ] `overline` — `single | double | none`.
- [ ] `overline_colour`.
- [ ] `rise` — points or `%`; negative subscript / positive superscript.
- [ ] `strikethrough` — `true | false`.
- [ ] `strikethrough_colour`.
- [ ] `href` — URL.

### 13.3 Convenience tags

- [ ] `<b>` bold. `<i>` italic. `<u>` underline. `<s>` strikethrough.
- [ ] `<big>` = `<span size="larger">`; `<small>` = `<span size="smaller">`.
- [ ] `<sub>` = `<span size="smaller" rise="-30%">`; `<sup>` = `<span size="smaller" rise="30%">`.
- [ ] `<tt>` monospace.

### 13.4 `<strut/>` (empty markup)

- [ ] Self-closing form `<strut/>`.
- [ ] Attributes: `label`, `width`/`w`, `ascender`/`a`, `descender`/`d` (points / `em` / `ex`).
- [ ] Used for bookmarks: `<strut label="verse"/>`.

### 13.5 `<sym name/>` (symbols)

- [ ] Attributes: `size`, `color`, `bgcolor`, `href`.
- [ ] Recognised names (chordpro-symbols):
  - Arrows: `arrow-up`, `arrow-down`, plus the variant suffixes `-with-accent`, `-with-accent-and-arpeggio`, `-with-accent-and-staccato`, `-with-arpeggio`, `-with-staccato`, `-muted`, `-muted-with-accent`, `-muted-with-accent-and-arpeggio`, `-muted-with-arpeggio` applied to each direction (10 names per direction). Concrete names include `arrow-down-with-staccato` and `arrow-up-with-staccato` (do not omit them when enumerating).
  - `arrow-mute` is a single, standalone name — it does **not** take the variant suffixes above.
  - Circled: `circle-0` … `circle-9`, `circle-A` … `circle-Z`.
  - Bars/repeats: `bar`, `double-bar`, `double-thick-bar`, `end-bar`, `repeat-colon`, `repeat-end`, `repeat-end-start`, `repeat-start`, `repeat1`, `repeat2`, `start-bar`, `thick-bar`.
  - Accidentals: `flat`, `natural`, `sharp`, `delta`.

### 13.6 `<img/>` (inline image)

See §10 — same `src=`/`id=`/`chord=` plus inline-only `dx`, `dy`, `bbox`, `w`, `h`.

### 13.7 Bookmarks

- [ ] Set: `<strut label="<id>"/>`. (markup, since 6.080)
- [ ] Reference: `<span href="#<id>">…</span>`.
- [ ] Built-ins: `cover`, `front`, `toc`, `top`, `back`, `song_1`, `song_2`, …
- [ ] Custom via metadata: `{meta: bookmark <id>}`.

### 13.8 Markup limits

- [ ] Markup inside chord brackets must not split the chord name (see §2.12).
- [ ] README notes the Dart parser preserves Pango markup verbatim (no inline rendering).

---

## 14. Chord-over-lyric (legacy) auto-conversion

- [ ] Chord-over-lyrics format detected and internally converted to ChordPro form. (chords-over-lyrics) Specific algorithm not formalised on this page.

---

## 15. Per-version timeline (summary)

For audit reference — what was added when, so an implementation can decide which targets are "must-have" for ChordPro 6:

- 6.000 (2022-12-28): drop `*` for user-defined chords; finger settings can be suppressed.
- 6.010 (2023-06-05): line continuation `\`; simple markup in chords; image `id=`, `x=`, `y=`, `anchor=` (experimental); image `scale=` as `%`; `\u` 4-digit Unicode escape; experimental `{define}` `diagram` control.
- 6.020 (2023-07-21): new `{diagrams}` directive (replaces `grid`/`no_grid`); pseudo-chord recovery (`|`, spaces) → annotations; `{define}` copy/copyall fixes.
- 6.030 (2023-09-18): `chorusfont`/`chorussize`/`choruscolour`; ABC/Lilypond → SVG; ABC `staffsep`; ABC `split` defaults to on.
- 6.040 (2023-12-26): `{ns toc=no}` ToC suppression; image anywhere (paper/page/column/line); inline `<img/>`; `{image}` `label`/`align`; resource libs.
- 6.042 (2024-01-09): runtime info inclusion control.
- 6.050 (2024-02-09): `start_of_textblock`/`end_of_textblock` env; ToC templates; delegate types `none`/`omit`.
- 6.060 (2024-08-24): `\u{X+}` brace Unicode escape; image `href`; `align` for diagrams; `label="…"` for `{chorus}` and `{grid}`; image scale comma-pair; `sog`/`eog` shortcodes; `{define}` allows fret `-1`.
- 6.070 (2024-12-25): `labelfont`/`labelsize`/`labelcolour`; `mi` shorthand for `min`; `%{}` substitutions in grid sections; experimental chord-changes; new metadata `page.class`/`page.side`; tweaked NC handling.
- 6.080 (2025-08-18): `sortartist`, `tag`; bookmarks; strum patterns in grids; emergency chord brackets; experimental `allpages` image anchor.
- 6.090 (2025-10-31): config file types (`instrument`/`style`/`stylemod`/`task`).
- 6.100 (2026-04-21): chords inside `{define}` / `{chord}` are transposable; `{transpose}` `k` qualifier (follow `{key}`); new substitutions `key.print` / `key.sound`; **removed `key_actual` / `key_from`** ("misleading and not useful", per keys_and_transpositions/) — supersede with `key.print` / `key.sound`; `keys.flats` config (default false — prefer `F#` over `F#/Gb`); `keys.force-common` config (default true — enforce 5-accidental max); `settings.wraplines` line-wrap toggle (default on); `html.style.embed` config (HTML output style embedding); jazzy chord names; image filenames may live next to song files; image filenames support leading `~` for home expansion; ChordPro suppresses `{key}` when transcoding to movable systems; duplicate ToC/outline lines de-duplicated; `settings.strict` default flipped to false.
- 6.101 (2026-04-30): housekeeping (license → Artistic 2.0; DISPLAY warning fix; PDF info `title` defaults to songbook title; `--text-font` crash fix). **No file-format additions** — checklist cut-off remains 6.100.

---

## 16. Known spec ambiguities

- [ ] Multi-chord-per-syllable behaviour and trailing-chord placement are not formalised in the spec; any concrete rule is parser-defined.
- [ ] The `colour` vs `color` synonym is not declared on the markup page; it is observable in implementations and confirmed by the README.
- [ ] Mode markers (`m` / `min` / `major`) on `{key}` values, and Nashville/Roman acceptance for `{key}`, are not stated on the directives-key page; the chord grammar shows root-form parity but the `{key}` page only shows `C`.
- [ ] `{pagetype}` value list is illustrative (`a4`, `letter`); implementations support more.
- [ ] Directive parser closes on the first unescaped `}`; therefore attribute values cannot embed literal `}`.
- [ ] The spec assumes a directive line; parsers that accept mid-lyric `{…}` are doing so as a non-spec extension.
- [ ] Backslash escapes within lyrics (`\[`, `\]`, `\{`, `\}`, `\\`) are not declared by the spec — README marks them as a non-spec leniency of this Dart parser.
- [ ] `{define}` page uses both `base-fret` (hyphen) and `base_fret` (underscore) interchangeably. Robust parsers should accept either spelling.
- [ ] `{image}` `bordertrbl=` (cheat sheet) vs `trbl=` (directives-image/) — same attribute, two names in the official docs. Accept both.
- [ ] `{image}` page omits `align=` and `label=` from its formal table even though they were added in 6.040; the cheat sheet and release notes confirm them — treat as documentation gap, not spec absence.
- [ ] Inline-`<img/>` attribute set vs block-`{image}` attribute set partially overlap; the directives-image page is the source of truth for the **block** form, the markup page for the **inline** form.

---

## 17. Audit instructions

When auditing the implementation against this checklist:

1. Treat each unchecked `[ ]` as a unit of work.
2. For each item, find a test (or add one) that exercises it. Mark `[x]` only when a test asserts the spec-correct behaviour.
3. README's "Non-spec extensions" table lists features the parser accepts beyond the spec — those are not in this checklist (by design).
4. README's "Known limitations" list flags items deferred (Pango rendering, `format=` interpretation, attribute `}` escaping, typed `{pagetype}` access). Audit should re-evaluate each before declaring spec conformance.
5. The "Per-version timeline" (§15) is the cut-off map: anything earlier than 6.0 is grandfathered ChordPro 1–5 surface; everything 6.0–6.100 is in-scope for ChordPro 6 conformance.
