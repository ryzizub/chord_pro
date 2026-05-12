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
    this.ccName,
    this.ccProgression = const [],
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
    final rawCc = attrs['cc'] ?? 'grid';
    final cc = _CcDecoded.parse(rawCc);
    if (shape == null) {
      return GridAttributes(
        cc: cc.raw,
        ccName: cc.name,
        ccProgression: cc.progression,
        label: label,
      );
    }
    final m = _shapeRe.firstMatch(shape);
    if (m == null) {
      return GridAttributes(
        cc: cc.raw,
        ccName: cc.name,
        ccProgression: cc.progression,
        label: label,
      );
    }
    return GridAttributes(
      leftMargin: m.group(1) == null ? null : int.parse(m.group(1)!),
      measures: int.parse(m.group(2)!),
      beats: m.group(3) == null ? null : int.parse(m.group(3)!),
      rightMargin: m.group(4) == null ? null : int.parse(m.group(4)!),
      shapeLabel: m.group(5),
      cc: cc.raw,
      ccName: cc.name,
      ccProgression: cc.progression,
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

  /// `cc=` chord-memorisation tag verbatim. Defaults to `"grid"` per
  /// spec; an explicit empty value disables memorisation.
  ///
  /// When the value follows the spec's `Name:C1 C2 …` form (since
  /// 6.070), see [ccName] / [ccProgression] for the decoded parts.
  final String cc;

  /// Name of the chord-change set when `cc="Name"` or `cc="Name:…"`
  /// (since ChordPro 6.070, experimental).
  ///
  /// `null` when [cc] is the default `"grid"` value or the empty
  /// memorisation-off marker.
  final String? ccName;

  /// Predefined chord progression when `cc="Name:C1 C2 …"` (since
  /// ChordPro 6.070, experimental). Empty when only a name is given.
  final List<String> ccProgression;

  /// `label="..."` from the start_of_grid directive (or the bare
  /// legacy form before the colon was added to the spec).
  final String? label;
}

class _CcDecoded {
  const _CcDecoded({
    required this.raw,
    required this.name,
    required this.progression,
  });

  factory _CcDecoded.parse(String raw) {
    if (raw.isEmpty || raw == 'grid') {
      return _CcDecoded(raw: raw, name: null, progression: const []);
    }
    final colon = raw.indexOf(':');
    if (colon < 0) {
      return _CcDecoded(raw: raw, name: raw, progression: const []);
    }
    final name = raw.substring(0, colon);
    final tail = raw.substring(colon + 1).trim();
    final progression = tail.isEmpty
        ? const <String>[]
        : tail.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    return _CcDecoded(
      raw: raw,
      name: name.isEmpty ? null : name,
      progression: List<String>.unmodifiable(progression),
    );
  }

  final String raw;
  final String? name;
  final List<String> progression;
}

final RegExp _shapeRe =
    RegExp(r'^(?:(\d+)\+)?(\d+)(?:x(\d+))?(?:\+(\d+))?(?:[:\s](.*))?$');
