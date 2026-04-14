import 'package:chord_pro/src/source/source_span.dart';

/// A single line of ChordPro source, as produced by the scanner.
///
/// [RawLine] is the intermediate representation shared by every later
/// stage. It holds the original text plus positional metadata so that
/// diagnostics and downstream tools can point back at the source.
class RawLine {
  /// Creates a new [RawLine].
  const RawLine({required this.number, required this.text});

  /// 1-based line number.
  final int number;

  /// The line contents, with the trailing newline stripped.
  final String text;

  /// A span covering the entire line.
  SourceSpan get span =>
      SourceSpan(line: number, column: 1, length: text.length);

  /// Whether the line contains only whitespace.
  bool get isBlank => text.trim().isEmpty;
}
