---
name: spec-audit
description: Check chord_pro against the latest ChordPro release and close or record audit gaps in chordpro-spec-checklist.md and test/spec_audit_test.dart. Use when ChordPro publishes a release, on a spec drift check, or when asked to audit the parser against the spec.
---

# Spec audit

Follow `.claude/rules/spec-audit.md` throughout.

## 1. Find what changed upstream

- Read the checklist banner for the current spec target and cut-off.
- Read `https://www.chordpro.org/chordpro/chordpro-reference-relnotes/` and
  `…/chordpro-version-history/` for releases after the target.
- For each newer release, list file-format changes: new or changed
  directives, attributes, chord grammar, metadata, markup. Runtime,
  packaging and rendering-only changes do not add parser obligations.

If nothing is newer, say so and stop.

## 2. Update the checklist

The edit hook asks first; say why in one line when it does.

- Refresh the banner: spec target, release date, cut-off.
- Add the release to §15 (per-version timeline).
- Add one `[ ]` item per new obligation in the matching section, with
  `since: X.Y`.

## 3. Add audit tests

For each new item, add a test to `test/spec_audit_test.dart` named with its
coordinate. If the parser does not satisfy it yet, mark it
`skip: 'AUDIT: <why>. Recorded in doc/reference/limitations.md.'` and add
the limitation.

## 4. Close what you can

For each gap that is a parser concern (not rendering), implement it as a
normal change: tick the item, un-skip the test, drop the limitation, add a
CHANGELOG entry. Larger ones go through `/brainstorm` → `/plan` first.

## 5. Ship

Run the full suite (the new audit tests must be green or skipped with a
reason), then use the `ship` skill. Title: `docs(spec): audit against
ChordPro X.Y` or `feat(spec): …` when the parser changed.
