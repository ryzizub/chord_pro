/// Typed shape and chord-context fields for `{start_of_grid}` per
/// `lib/ChordPro/Song.pm:1479-1525`.
///
/// The shape regex is
/// `^(?:(\d+)\+)?(\d+)(?:x(\d+))?(?:\+(\d+))?(?:[:\s+](.*)?)?$`,
/// matching `left+measures x beats+right` with an optional trailing
/// label segment. `cc` defaults to `"grid"`; an explicit empty value
/// disables chord memorisation.
class GridAttributes {
  /// Creates a new [GridAttributes].
  const GridAttributes({
    this.leftMargin,
    this.measures,
    this.beats,
    this.rightMargin,
    this.shapeLabel,
    this.cc = 'grid',
    this.label,
  });

  /// Decodes a [GridAttributes] from the parsed start-of-grid
  /// attribute map.
  ///
  /// [attrs] should already have `label` removed; pass it separately
  /// via [label].
  factory GridAttributes.fromAttributes(
    Map<String, String> attrs, {
    String? label,
  }) {
    final shape = attrs['shape'];
    final cc = attrs['cc'] ?? 'grid';
    if (shape == null) {
      return GridAttributes(cc: cc, label: label);
    }
    final m = _shapeRe.firstMatch(shape);
    if (m == null) {
      return GridAttributes(cc: cc, label: label);
    }
    return GridAttributes(
      leftMargin: m.group(1) == null ? null : int.parse(m.group(1)!),
      measures: int.parse(m.group(2)!),
      beats: m.group(3) == null ? null : int.parse(m.group(3)!),
      rightMargin: m.group(4) == null ? null : int.parse(m.group(4)!),
      shapeLabel: m.group(5),
      cc: cc,
      label: label,
    );
  }

  /// Cells to the left of the bar (the `\d+\+` prefix on the shape).
  final int? leftMargin;

  /// Number of measures (or, when [beats] is null, the bare cell count).
  final int? measures;

  /// Beats per measure — the `xN` part of `MxN`. `null` when the shape
  /// is bare cells.
  final int? beats;

  /// Cells to the right of the bar.
  final int? rightMargin;

  /// Trailing label segment embedded in the shape value (after `:` or
  /// whitespace), if any.
  final String? shapeLabel;

  /// `cc=` chord-memorisation tag. Defaults to `"grid"` per spec; an
  /// empty value disables memorisation.
  final String cc;

  /// `label="..."` from the start_of_grid directive (or the bare
  /// legacy form before the colon was added to the spec).
  final String? label;
}

final RegExp _shapeRe =
    RegExp(r'^(?:(\d+)\+)?(\d+)(?:x(\d+))?(?:\+(\d+))?(?:[:\s](.*))?$');
