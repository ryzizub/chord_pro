import 'package:chord_pro/src/ast/section.dart';
import 'package:chord_pro/src/directive/image_directive.dart';
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

  /// An embedded image emitted by `{image: …}`.
  image,

  /// A layout break emitted by `{new_page}` / `{column_break}` etc.
  layoutBreak,
}

/// Which kind of layout break a [Line] requests.
enum LayoutBreak {
  /// `{new_page}` / `{np}`.
  newPage,

  /// `{new_physical_page}` / `{npp}`.
  newPhysicalPage,

  /// `{column_break}` / `{colb}`.
  columnBreak,
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
/// [commentStyle]; image lines carry an [image] payload.
class Line {
  /// Creates a structured line whose body is a list of [InlineToken]s.
  const Line({required this.tokens, required this.span})
      : kind = LineKind.structured,
        verbatim = null,
        comment = null,
        commentStyle = null,
        image = null,
        layoutBreak = null;

  /// Creates a verbatim line (used inside tab/grid/abc/ly blocks).
  const Line.verbatim({required String this.verbatim, required this.span})
      : kind = LineKind.verbatim,
        tokens = const [],
        comment = null,
        commentStyle = null,
        image = null,
        layoutBreak = null;

  /// Creates a comment line emitted by a `{comment}`-family directive.
  const Line.comment({
    required String this.comment,
    required CommentStyle this.commentStyle,
    required this.span,
  })  : kind = LineKind.comment,
        tokens = const [],
        verbatim = null,
        image = null,
        layoutBreak = null;

  /// Creates an image line emitted by an `{image: …}` directive.
  const Line.image({
    required ImageDirective this.image,
    required this.span,
  })  : kind = LineKind.image,
        tokens = const [],
        verbatim = null,
        comment = null,
        commentStyle = null,
        layoutBreak = null;

  /// Creates a layout-break line emitted by `{new_page}` and friends.
  const Line.layoutBreak({
    required LayoutBreak this.layoutBreak,
    required this.span,
  })  : kind = LineKind.layoutBreak,
        tokens = const [],
        verbatim = null,
        comment = null,
        commentStyle = null,
        image = null;

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

  /// Embedded image directive, or `null` if not an image line.
  final ImageDirective? image;

  /// Layout break kind, or `null` if not a layout-break line.
  final LayoutBreak? layoutBreak;

  /// Source span covering the original line.
  final SourceSpan span;

  /// Whether this line was captured verbatim.
  bool get isVerbatim => kind == LineKind.verbatim;

  /// Whether this line is a comment-style annotation.
  bool get isComment => kind == LineKind.comment;

  /// Whether this line is an embedded image.
  bool get isImage => kind == LineKind.image;

  /// Whether this line is a layout break.
  bool get isLayoutBreak => kind == LineKind.layoutBreak;
}
