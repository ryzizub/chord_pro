import 'package:chord_pro/src/ast/section.dart';
import 'package:chord_pro/src/inline/inline_token.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// A single rendered line within a [Section].
///
/// Structured lines (verse/chorus/bridge/loose) carry parsed
/// [tokens]. Verbatim lines (tab/grid/abc/ly) carry raw text via
/// [verbatim].
class Line {
  /// Creates a structured line whose body is a list of [InlineToken]s.
  const Line({required this.tokens, required this.span}) : verbatim = null;

  /// Creates a verbatim line (used inside tab/grid/abc/ly blocks).
  const Line.verbatim({required String this.verbatim, required this.span})
      : tokens = const [];

  /// Parsed tokens for a structured line.
  final List<InlineToken> tokens;

  /// Raw text for a verbatim line, or `null` if structured.
  final String? verbatim;

  /// Source span covering the original line.
  final SourceSpan span;

  /// Whether this line was captured verbatim.
  bool get isVerbatim => verbatim != null;
}
