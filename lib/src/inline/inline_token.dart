import 'package:chord_pro/src/chord/chord.dart';
import 'package:chord_pro/src/directive/directive.dart';
import 'package:chord_pro/src/source/source_span.dart';

/// Base class for tokens produced by the inline tokenizer.
sealed class InlineToken {
  const InlineToken({required this.span});

  /// Where in the source this token lives.
  final SourceSpan span;
}

/// Plain lyric text.
final class TextToken extends InlineToken {
  /// Creates a new [TextToken].
  const TextToken({required this.text, required super.span});

  /// The text content.
  final String text;

  @override
  String toString() => 'TextToken($text)';
}

/// A `[chord]` token.
///
/// [chord] is `null` when the bracketed content could not be parsed as
/// a chord (the raw form is still available via [raw]).
final class ChordToken extends InlineToken {
  /// Creates a new [ChordToken].
  const ChordToken({
    required this.raw,
    required this.chord,
    required super.span,
  });

  /// Original text inside the brackets (without the brackets).
  final String raw;

  /// Parsed chord, if recognisable.
  final Chord? chord;

  @override
  String toString() => 'ChordToken($raw)';
}

/// A `[*marker]` annotation token.
final class AnnotationToken extends InlineToken {
  /// Creates a new [AnnotationToken].
  const AnnotationToken({required this.text, required super.span});

  /// Annotation text (without the leading `*`).
  final String text;

  @override
  String toString() => 'AnnotationToken($text)';
}

/// A `[^]` chord-recall token (ChordPro 6.070, experimental).
///
/// Inside a lyric or grid line, `[^]` means "recall the next chord from
/// the active chord-change set (`cc`)" rather than spelling out a chord
/// name. The parser emits this dedicated token type so that renderers can
/// implement the recall semantics without inspecting the raw string.
///
/// Spec: <https://www.chordpro.org/chordpro/ChordChanges/>
final class ChordRecallToken extends InlineToken {
  /// Creates a new [ChordRecallToken].
  const ChordRecallToken({required super.span});

  @override
  String toString() => 'ChordRecallToken()';
}

/// An inline `{…}` directive inside a lyric line.
final class InlineDirectiveToken extends InlineToken {
  /// Creates a new [InlineDirectiveToken].
  const InlineDirectiveToken({
    required this.directive,
    required super.span,
  });

  /// The parsed directive.
  final Directive directive;

  @override
  String toString() => 'InlineDirectiveToken($directive)';
}
