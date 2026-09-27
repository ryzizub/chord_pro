# Architecture decision records

One decision per file, numbered in order. A decision that changes gets a new
record, and the old one's status points at it; records are never deleted.

| ADR | Decision | Status |
| --- | --- | --- |
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-zero-runtime-dependencies.md) | Zero runtime dependencies | Accepted |
| [0003](0003-one-pass-staged-pipeline.md) | One-pass staged pipeline with tiered imports | Accepted |
| [0004](0004-lossless-directive-stream.md) | Lossless directive stream; selectors gate, they do not delete | Accepted |
| [0005](0005-immutable-value-ast.md) | Immutable value AST, copy-on-transform | Accepted |
| [0006](0006-parsing-never-throws.md) | Parsing never throws; problems are coded diagnostics | Accepted |
| [0007](0007-spec-driven-audit.md) | The spec checklist is ground truth, audited in both directions | Accepted |
| [0008](0008-config-options-as-parameters.md) | Reference-implementation config options are threaded parameters | Accepted |

Template:

```markdown
# NNNN. Title

- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```
