# Directives

Facts per the [ChordPro directive reference][cp_directives].

- **Metadata** — `title` / `t`, `sorttitle`, `subtitle` / `st`, `artist`, `sortartist`, `composer`, `lyricist`, `arranger`, `copyright`, `album`, `year`, `key`, `time`, `tempo`, `duration`, `capo`, `transpose` (with optional `s`/`f`/`k`/`#`/`b`/`♯`/`♭` qualifier), `columns` / `col`, `tag`, plus `{meta: key value}` desugaring. `key`, `time`, `tempo`, `sorttitle`, and `sortartist` are multi-valued per spec (one `sorttitle` per `title`; each `{key}` applies from its source position). Auto-generated names (`_key`, `key.print`, `today`, `instrument`, `user`, `page`, …) are reserved.
- **Comments** — `{comment}`, `{ci}`, `{cb}`, `{highlight}` emit as in-flow comment lines.
- **Images** — `{image: …}` parsed into a typed `ImageDirective` with full attribute coverage: `src`, `width`, `height`, `scale`, `align`, `border`, `bordertrbl` (`trbl=` accepted as alias), `title`, `label`, `href`, `id`, `chord`, `type`, `x`, `y`, `spread`, `center`, `persist`, `omit`, plus a validated `anchorEnum` (`paper` / `page` / `allpages` / `column` / `float` / `line`).
- **Layout breaks** — `{new_page}`, `{new_physical_page}`, `{column_break}` emit as in-flow layout breaks.
- **Output / song boundary** — `{ns toc=no}` (or `toc=false` / `toc=0`) sets `Song.tocSuppressed`. `{titles: left|center|right}` and `{diagrams: on|off|top|bottom|right|below}` (with `{g}` alias) become typed song-level settings.
- **Formatting** — `chordfont`, `textsize`, `titlecolour`, … reduce into `FormattingSettings`. Both `colour` and `color` accepted.
- **Custom** — `x_*` extensions preserved on `Song.customExtensions`.

[cp_directives]: https://www.chordpro.org/chordpro/chordpro-directives/
