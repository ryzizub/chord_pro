import 'package:chord_pro/src/ast/line.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// What kind of block a [Section] represents.
enum SectionKind {
  /// Lines that belong to no explicit environment.
  loose,

  /// `{start_of_verse}` … `{end_of_verse}`.
  verse,

  /// `{start_of_chorus}` … `{end_of_chorus}`.
  chorus,

  /// `{start_of_bridge}` … `{end_of_bridge}`.
  bridge,

  /// `{start_of_tab}` … `{end_of_tab}` (verbatim).
  tab,

  /// `{start_of_grid}` … `{end_of_grid}` (verbatim).
  grid,

  /// `{start_of_abc}` … `{end_of_abc}` (verbatim).
  abc,

  /// `{start_of_ly}` … `{end_of_ly}` (verbatim).
  ly,

  /// Custom `{start_of_X}` environment not recognised above.
  custom,
}

/// A contiguous block of lines that share a [SectionKind].
class Section {
  /// Creates a new [Section].
  const Section({
    required this.kind,
    required this.lines,
    required this.span,
    this.label,
    this.customKind,
    this.isChorusRecall = false,
  });

  /// Which environment produced this section.
  final SectionKind kind;

  /// Optional label (e.g. `{sov: Verse 1}` → `"Verse 1"`).
  final String? label;

  /// When [kind] is [SectionKind.custom], the raw custom name.
  final String? customKind;

  /// Lines inside the section, in source order.
  final List<Line> lines;

  /// Span covering the whole section, start-directive to end-directive.
  final SourceSpan span;

  /// True when this section is a bare `{chorus}` recall rather than an
  /// authored chorus body.
  final bool isChorusRecall;
}
