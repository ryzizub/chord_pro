---
paths:
  - "chordpro-spec-checklist.md"
  - "test/spec_audit_test.dart"
  - "test/spec_coverage_test.dart"
  - "doc/reference/non-spec-extensions.md"
  - "doc/reference/limitations.md"
---

# Spec audit

The checklist is the spec; the parser is checked against it.

- `chordpro-spec-checklist.md` changes only when chordpro.org changes (a new
  release, a corrected page) or an audit gap closes. Never edit it to match
  the code. The edit hook asks first.
- One test in `test/spec_audit_test.dart` per checklist item, named with its
  coordinate: `'[§4.2] {key} populates key'`. Tests assert what the spec
  says, so a red audit test is a finding about the parser.
- A known gap is `skip: 'AUDIT: <why>. Recorded in doc/reference/limitations.md.'`.
  Never delete an audit test to get green.
- Closing a gap is one change: tick the checklist item, remove the `skip:`,
  remove the entry from `doc/reference/limitations.md`, add a CHANGELOG line.
- Accepting input the spec does not define is an extension: document it in
  `doc/reference/non-spec-extensions.md` in the same change, or
  `test/spec_coverage_test.dart` fails. Its `_allowlist` stays empty.
- A ticked subsection needs at least one `[§…]` coordinate in the audit file
  (checked by `spec_coverage_test`).
- On a new ChordPro release: refresh the banner (spec target, cut-off, date),
  add the version to §15, add items for any new file-format feature (as
  `[ ]` until implemented), then re-run the suite. The `spec-audit` skill
  walks through it.
