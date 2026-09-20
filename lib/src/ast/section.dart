import 'package:chord_pro/src/ast/grid_attributes.dart';
import 'package:chord_pro/src/ast/line.dart';
import 'package:chord_pro/src/ast/textblock_attributes.dart';
import 'package:chord_pro/src/source/source_span.dart';
import 'package:chord_pro/src/util/equality.dart';

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

  /// `{start_of_svg}` … `{end_of_svg}` (verbatim).
  svg,

  /// `{start_of_textblock}` … `{end_of_textblock}` (verbatim).
  textblock,

  /// `{start_of_grille}` … `{end_of_grille}` (verbatim).
  ///
  /// Experimental delegated environment in the reference implementation
  /// (`Grille.pm`). Produces a chord-grid image via the delegate; the body
  /// is raw chord-grid notation and must be captured verbatim.
  /// Spec: https://www.chordpro.org/chordpro/directives-env_grille/
  grille,

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
    this.isSelectorSuppressed = false,
    this.attributes = const {},
  });

  /// Which environment produced this section.
  final SectionKind kind;

  /// Optional label (e.g. `{sov: Verse 1}` → `"Verse 1"`, or
  /// `{start_of_verse: label="Verse 1"}` → `"Verse 1"`).
  final String? label;

  /// When [kind] is [SectionKind.custom], the raw custom name.
  final String? customKind;

  /// Lines inside the section, in source order.
  final List<Line> lines;

  /// Span covering the section, from its start directive.
  ///
  /// [SourceSpan] never crosses a line boundary, so this covers the whole
  /// section only when it opens and closes on the same line. For the
  /// usual multi-line section it points at the start directive; use
  /// `lines.last.span` for where the body ends.
  final SourceSpan span;

  /// True when this section is a bare `{chorus}` recall rather than an
  /// authored chorus body.
  final bool isChorusRecall;

  /// True when the section's start directive carried a selector that was
  /// not active for this parse, e.g. `{start_of_verse-guitar}` parsed
  /// without `guitar` in `selectors`.
  ///
  /// The body lines are still captured — tokenized exactly as they would
  /// have been had the selector applied — so a consumer can re-emit the
  /// document losslessly or render the section anyway. A renderer
  /// honouring the selector should skip these; `Song.activeSections` does
  /// that filtering.
  ///
  /// Directives *inside* the suppressed range are not replayed as [lines]:
  /// they stay in `Song.directives` (in source order, with their spans)
  /// and are deliberately not applied, since the selector said to skip
  /// them. So a `{comment}` inside a suppressed verse is reachable from
  /// the directive stream rather than from [lines].
  ///
  /// Spec: https://www.chordpro.org/chordpro/chordpro-configuration-selectors/
  final bool isSelectorSuppressed;

  /// Any extra `key=value` attributes parsed from the start-of
  /// directive body, **excluding** `label` (which is surfaced via the
  /// dedicated [label] field).
  ///
  /// Keys are lowercased. Empty for sections without a start-directive
  /// body or whose body collapsed entirely into [label].
  final Map<String, String> attributes;

  /// Typed grid attributes (shape, cc), only populated when
  /// [kind] is [SectionKind.grid].
  ///
  /// Decoded on each access (the shape is re-matched and a new
  /// [GridAttributes] allocated), so hoist it out of a render loop
  /// rather than reading it per line.
  GridAttributes? get gridAttributes => kind == SectionKind.grid
      ? GridAttributes.fromAttributes(attributes, label: label)
      : null;

  /// Typed textblock attributes, only populated when
  /// [kind] is [SectionKind.textblock].
  ///
  /// Decoded on each access, like [gridAttributes].
  TextblockAttributes? get textblockAttributes => kind == SectionKind.textblock
      ? TextblockAttributes.fromAttributes(attributes)
      : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Section &&
          other.kind == kind &&
          other.label == label &&
          other.customKind == customKind &&
          listEquals(other.lines, lines) &&
          other.span == span &&
          other.isChorusRecall == isChorusRecall &&
          other.isSelectorSuppressed == isSelectorSuppressed &&
          mapEquals(other.attributes, attributes);

  @override
  int get hashCode => Object.hash(
        kind,
        label,
        customKind,
        Object.hashAll(lines),
        span,
        isChorusRecall,
        isSelectorSuppressed,
        mapHash(attributes),
      );
}
