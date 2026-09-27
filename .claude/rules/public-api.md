---
paths:
  - "lib/**"
---

# Public API

- `lib/chord_pro.dart` is the only public import. Every export names its
  symbols with `show`; a new public type or function is added there in the
  same change, and a helper that should stay internal is left out.
- Every public member has dartdoc. Say what it returns for edge cases
  (empty input, unknown directive) and link the spec page where one applies.
- Public types are immutable values: `final` fields, `const` constructors
  where possible, unmodifiable collections (`List.unmodifiable`), structural
  `==` and `hashCode` via `lib/src/util/equality.dart`. Transformations
  return new values.
- Parsing reports problems as `Diagnostic`s. Throw only for caller errors,
  with a specific `Error` subtype, documented as "Throws [ArgumentError]
  when …" in the dartdoc.
- Stay within the SDK floor in `pubspec.yaml` (`^3.5.0`): no language
  features newer than that (dot shorthands, declaring constructors, null-aware
  elements) unless the floor is raised deliberately, with a CHANGELOG entry.
- No runtime dependencies. Anything from `package:meta`, `collection` or
  similar is written locally in `lib/src/util/` or done without.
- Imports inside `lib/src/` use `package:chord_pro/src/…` and follow the
  tier rules in CLAUDE.md; nothing in `lib/src/` imports the barrel.
- Breaking changes are allowed pre-1.0 but are always called out: adding a
  subtype to a `sealed` class, renaming or removing a member, changing a
  default. They bump the minor version and go under `### Breaking`.
