# Conditional selectors

- Positive form `{title-guitar: …}` and spec-form negation `{title-guitar!: …}`.
- Gates metadata, formatting, sections, comments, images, layout breaks, chord recalls, and `{define}` / `{chord}` definitions.

Legacy negative forms the parser still accepts are listed under [non-spec extensions](../reference/non-spec-extensions.md).

Because the selector separator is a hyphen and the spec gives no way to escape it, a hyphen anywhere in a directive name is read as one: `{x_mytool-config: …}` parses as the directive `x_mytool` with the selector `config`. Use underscores in custom `x_*` directive names to avoid it.

See also: [passing a selector set](../usage/transposing.md).
