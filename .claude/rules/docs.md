---
paths:
  - "doc/**"
  - "docs/**"
  - "README.md"
  - "CHANGELOG.md"
---

# Docs

- `doc/` is user documentation and ships with the package. `docs/` is for
  contributors and is excluded from the published package by `.pubignore`.
- **ADRs** (`docs/adr/NNNN-title.md`): one decision each, with Status,
  Context, Decision and Consequences. A change that reverses or extends a
  decision updates that ADR's status and adds a new one in the same PR;
  ADRs are never deleted. `docs/adr/README.md` indexes them.
- **Brainstorms and plans** (`docs/brainstorm/`, `docs/plan/`) are written by
  `vgv-wingspan`. Commit each with the change it led to. Never delete or
  rewrite them after the fact; they record what was intended.
- **CHANGELOG.md**: new work goes under `## Unreleased` with `### Breaking`,
  `### New`, `### Fixed` subsections. Headings carry no dates. Each entry
  describes the API change from a package user's side, names the issue, and
  links the spec page. A breaking entry says what to change.
- **README.md** stays short (pitch, install, quick start, links into `doc/`).
  Details go in `doc/`.
- Divergences from the spec go in `doc/reference/non-spec-extensions.md`
  (more lenient than the spec) or `doc/reference/limitations.md` (spec
  feature not implemented).
- Code samples in `doc/` must compile against the current API.
