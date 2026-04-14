/// A half-open position range in the original ChordPro source.
///
/// Line and column are 1-based; [length] is the number of characters on
/// [line] starting at [column] that this span covers. Spans never cross
/// line boundaries — the parser produces at most one span per line.
class SourceSpan {
  /// Creates a new [SourceSpan].
  const SourceSpan({
    required this.line,
    required this.column,
    required this.length,
  });

  /// 1-based line number.
  final int line;

  /// 1-based column of the first covered character.
  final int column;

  /// Number of characters covered on [line].
  final int length;

  @override
  String toString() => '$line:$column+$length';
}
