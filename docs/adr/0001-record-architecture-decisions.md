# 0001. Record architecture decisions

- Status: Accepted
- Date: 2026-09-27

## Context

The decisions that shape chord_pro were recorded only in `CLAUDE.md`,
commit messages and the CHANGELOG. A contributor, human or agent, changing
the pipeline or the AST had no single place to learn why it is built the way
it is, so the same questions came back in reviews.

## Decision

Architecture decisions are recorded as short ADRs in `docs/adr/`, one per
file. ADRs 0002 to 0008 record decisions already in force when this
practice began. A PR that changes a decision adds or updates an ADR.

## Consequences

`docs/` is contributor documentation and is excluded from the published
package; user documentation stays in `doc/`.
