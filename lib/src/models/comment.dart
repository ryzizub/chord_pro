import 'package:chord_pro/src/models/directive.dart';

/// Model representing comments in a chord sheet
class Comment with DirectiveMixin<Comment> {
  /// Creates a new Comment instance
  Comment({
    this.comment,
    this.commentItalic,
    this.commentBox,
    this.highlight,
  });

  /// Creates instance of [Comment] from created map of already
  /// parsed content of Chordpro
  factory Comment.fromDirectiveMap(Map<String, List<String>> map) {
    final comment = _retrieveCommentValue(map, ['comment', 'c']);
    final commentItalic = _retrieveCommentValue(map, ['comment_italic', 'ci']);
    final commentBox = _retrieveCommentValue(map, ['comment_box', 'cb']);
    final highlight = _retrieveCommentValue(map, ['highlight']);

    return Comment(
      comment: comment,
      commentItalic: commentItalic,
      commentBox: commentBox,
      highlight: highlight,
    );
  }

  /// Regular comments (shown with grey background historically)
  final List<String>? comment;

  /// Italic comments
  final List<String>? commentItalic;

  /// Box-styled comments
  final List<String>? commentBox;

  /// Highlighted comments
  final List<String>? highlight;

  @override
  bool isEmpty() {
    return [
      comment?.isEmpty,
      commentItalic?.isEmpty,
      commentBox?.isEmpty,
      highlight?.isEmpty,
    ].nonNulls.isEmpty;
  }
}

/// Accounts for retrieving value even when it's under {meta: key ....}
List<String>? _retrieveCommentValue(
  Map<String, List<String>> map,
  List<String> keys,
) {
  for (final key in keys) {
    if (map[key] != null && map[key]!.isNotEmpty) {
      return map[key];
    }
  }
  return null;
}
