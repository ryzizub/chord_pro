# 0009. Assembler as a private stateful class with one method per dispatch branch

- Status: Accepted
- Date: 2026-10-10

## Context

`assemble` was a single function holding all per-pass and per-song state in
locals and closures, with every dispatch branch inline in one loop. It scored
211 on cognitive complexity. CI now gates the codebase with
`cognitive_complexity@2.0.0` at a fail threshold of 15 per function, which
that shape cannot pass.

## Decision

`assemble` is a thin driver over a private `_Assembler` class. The class
holds the same state `assemble` held (same names and comments), and
`finishSong()` still flushes all per-song state. `addLine` dispatches each
`RawLine` to one method per branch, keeping the load-bearing order from
`.claude/rules/assembler.md`: suppressed-section body, open verbatim body,
then `_addDirective`, which appends to the directive stream first, then
handles the song boundary, song-level settings, the selector gate, and the
applying branches (definitions, chorus recall, section start, comment,
layout break, image, section end, fallthrough).

Section start (auto-close of an enclosing section, attribute parsing) is one
method shared by applying and selector-suppressed start directives.

Parsing is still one forward pass in one stateful stage. This extends
ADR 0003 and does not reverse it.

## Consequences

- A new directive gets a new method and a call in the right slot of the
  dispatch, rather than a new inline block.
- Each spec or `Song.pm` citation lives on the method for its branch.
- The class is private, so the public API and `assemble`'s signature do not
  change.
