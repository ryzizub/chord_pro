# Sections

- Built-in environments: `verse` / `sov`, `chorus` / `soc`, `bridge` / `sob`, `tab` / `sot`, `grid` / `sog`.
- Delegated `abc`, `ly`, `svg`, `textblock` captured verbatim.
- Custom `start_of_<name>` / `end_of_<name>` sections preserved with their custom kind.
- `label="…"` attribute parsed for every `{start_of_*}` (alongside the legacy bare-value form).
- `{start_of_grid}` exposes typed `shape` (left+measures × beats+right), `cc` (plus decoded `ccName` / `ccProgression` for the 6.070 `cc="Name:C1 C2 …"` form), and `label` via `Section.gridAttributes`.
- `{start_of_textblock}` exposes the full ChordPro 6.050 attribute set (textblock-specific plus image-inherited) via `Section.textblockAttributes`.
- `{chorus}` recall accepts all four spec forms — `{chorus}`, `{chorus: Final}`, `{chorus: label="Final"}`, `{chorus label="Final"}`.

See also: [walking sections and lines](../usage/parsing.md).
