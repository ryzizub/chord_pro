---
paths:
  - "lib/src/assembler/**"
---

# Assembler

`assemble` is the only stateful stage. Keep it a single forward pass.

- Branch order in the main loop is load-bearing: suppressed-section body →
  open verbatim body → song boundary → song-level settings → selector gate →
  definitions → chorus recall → section start/end → comment/layout/image →
  fallthrough. A new directive gets a branch in the right slot, not at the top.
- Every directive is appended to the song's directive stream before a branch
  decides what else to do with it, including selector-suppressed ones. Never
  `continue` past that append. Inside a verbatim body (tab, abc, ly, svg,
  textblock, grille, grid) only the matching `end_of_X` is a directive;
  every other line, brace-leading or not, is body text.
- Selector-suppressed content is flagged (`Section.isSelectorSuppressed`),
  never dropped. Typed reductions filter selectors themselves.
- `finishSong()` flushes all per-song state. New per-song state must be reset
  there, or it leaks into the next `{new_song}`.
- Each branch carries a comment citing the spec page
  (`https://www.chordpro.org/chordpro/directives-…/`) or the reference
  implementation line (`Song.pm:1382`) that justifies it.
- A new config option is a named parameter threaded from `ChordPro.parse`
  and `ChordPro.parseSong` through `assemble` to the stage that needs it.
  No globals, no statics.
- Malformed input produces a `Diagnostic` with a new or existing
  `DiagnosticCode` and the directive's `SourceSpan`; it never throws.
- Anything the dispatch recognises by name must be in a spec ledger
  (`.claude/rules/spec-audit.md`).
