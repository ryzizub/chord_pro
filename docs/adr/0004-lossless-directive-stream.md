# 0004. Lossless directive stream; selectors gate, they do not delete

- Status: Accepted
- Date: 2026-09-27 (suppressed sections kept since 0.8.0)

## Context

Renderers, editors and round-trip tools need everything the author wrote,
including directives whose selector does not apply to this parse and
directives the parser has no typed view for. Dropping them makes
re-emitting a song lossy (issue #36).

## Decision

`Song.directives` holds every directive in source order, including
selector-suppressed ones. Typed views (`Song.metadata`, `Song.formatting`)
are reductions over that stream and apply selectors themselves. A
selector-suppressed `{start_of_X-sel}` still produces a `Section` with its
body, flagged `isSelectorSuppressed`; `Song.activeSections` is the view
that honours selectors.

Inside a verbatim environment only the matching `end_of_X` is a directive;
other lines, including brace-leading ones, are body text (issue #35).

## Consequences

- A feature is never implemented by dropping a directive from the stream.
- Consumers choose between `sections` (everything) and `activeSections`
  (what a selector-honouring renderer prints).
