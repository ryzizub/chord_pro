import 'package:chord_pro/src/ast/section.dart';
import 'package:chord_pro/src/inline/inline_token.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// What flavour of content a [Line] carries.
enum LineKind {
  /// Lyrics + chords broken into [InlineToken]s.
  structured,

  /// Raw text from a verbatim block (tab/grid/abc/ly/svg/textblock).
  verbatim,

  /// A typeset comment emitted by `{comment}` and friends.
  comment,
}

/// Visual style requested by a comment-family directive.
enum CommentStyle {
  /// `{comment}` / `{c}`.
  plain,

  /// `{comment_italic}` / `{ci}`.
  italic,

  /// `{comment_box}` / `{cb}`.
  box,

  /// `{highlight}`.
  highlight,
}

/// A single rendered line within a [Section].
///
/// Structured lines carry parsed [tokens]; verbatim lines carry raw
/// [verbatim] text; comment lines carry a [comment] string and a
/// [commentStyle].
class Line {
  /// Creates a structured line whose body is a list of [InlineToken]s.
  const Line({required this.tokens, required this.span})
      : kind = LineKind.structured,
        verbatim = null,
        comment = null,
        commentStyle = null;

  /// Creates a verbatim line (used inside tab/grid/abc/ly blocks).
  const Line.verbatim({required String this.verbatim, required this.span})
      : kind = LineKind.verbatim,
        tokens = const [],
        comment = null,
        commentStyle = null;

  /// Creates a comment line emitted by a `{comment}`-family directive.
  const Line.comment({
    required String this.comment,
    required CommentStyle this.commentStyle,
    required this.span,
  })  : kind = LineKind.comment,
        tokens = const [],
        verbatim = null;

  /// Discriminator across line flavours.
  final LineKind kind;

  /// Parsed tokens for a structured line.
  final List<InlineToken> tokens;

  /// Raw text for a verbatim line, or `null` if not verbatim.
  final String? verbatim;

  /// Comment text (without the directive name), or `null` if not a comment.
  final String? comment;

  /// Comment style, or `null` if not a comment.
  final CommentStyle? commentStyle;

  /// Source span covering the original line.
  final SourceSpan span;

  /// Whether this line was captured verbatim.
  bool get isVerbatim => kind == LineKind.verbatim;

  /// Whether this line is a comment-style annotation.
  bool get isComment => kind == LineKind.comment;
}
