import 'package:chord_pro/src/assembler/assembler.dart';
import 'package:chord_pro/src/ast/song.dart';
import 'package:chord_pro/src/diagnostic/parse_result.dart';

/// A function that transforms a single source line before parsing.
///
/// Used with the [ChordPro.parse] `preprocessors` parameter to implement
/// the `parser.preprocess` ChordPro configuration option. Each preprocessor
/// receives one physical line of the source (before continuation-line joining
/// and Unicode-escape resolution) and returns the transformed line.
///
/// Preprocessors are applied in list order; the output of each is the input
/// to the next.
typedef Preprocessor = String Function(String line);

/// Public entry point for parsing ChordPro documents.
class ChordPro {
  const ChordPro._();

  /// Parses [source] and returns every song it contains plus diagnostics.
  ///
  /// Documents are split on `{new_song}` / `{ns}`; an empty document
  /// still yields a single empty [Song].
  ///
  /// [selectors] names the conditional selectors that should be treated
  /// as active. Directives carrying a positive selector (`{title-print}`)
  /// only contribute to typed metadata and formatting when the selector
  /// is in this set; directives with a negative selector
  /// (`{title-!print}` or legacy `{title+print}`) only contribute when it
  /// is not.
  ///
  /// [altBrackets] mirrors the `parser.altbrackets` configuration: when
  /// set to a two-character pair (e.g. `«»`), those characters are read
  /// as chord brackets.
  ///
  /// The rewrite is applied to lyric lines only. Directive values and
  /// verbatim bodies (`tab`, `grid`, `abc`, `ly`, `svg`, `textblock`,
  /// `grille`) keep the characters verbatim, so a song that uses `«»`
  /// as quotation marks in a `{title}` or inside a tab block is not
  /// mangled. Throws [ArgumentError] when the pair is not exactly two
  /// characters.
  ///
  /// [notesMode] mirrors the `settings.notes` configuration option: when
  /// `true`, lowercase `a`–`g` are accepted as letter-system chord roots.
  ///
  /// [strict] mirrors `settings.strict`: when `true`, a warning is emitted
  /// for each song that lacks a `{key}` directive. Defaults to `false`,
  /// consistent with the ChordPro 6.100 change that made forgiving the
  /// built-in default.
  ///
  /// [preprocessors] mirrors the `parser.preprocess` ChordPro configuration
  /// option. Each [Preprocessor] is applied to every physical source line
  /// (in list order) before the scanner processes it. Use this to implement
  /// custom line-level rewrites — for example, normalising alternate chord
  /// spellings or stripping proprietary markup.
  static ParseResult parse(
    String source, {
    Set<String> selectors = const {},
    String? altBrackets,
    bool notesMode = false,
    bool strict = false,
    List<Preprocessor> preprocessors = const [],
  }) {
    _validateAltBrackets(altBrackets);
    return assemble(
      source,
      selectors: selectors,
      notesMode: notesMode,
      strict: strict,
      preprocessors: preprocessors,
      altBrackets: altBrackets,
    );
  }

  /// Convenience wrapper that returns the first song of [source].
  static Song parseSong(
    String source, {
    Set<String> selectors = const {},
    String? altBrackets,
    bool notesMode = false,
    bool strict = false,
    List<Preprocessor> preprocessors = const [],
  }) =>
      parse(
        source,
        selectors: selectors,
        altBrackets: altBrackets,
        notesMode: notesMode,
        strict: strict,
        preprocessors: preprocessors,
      ).songs.first;
}

void _validateAltBrackets(String? pair) {
  if (pair == null) return;
  if (pair.runes.length != 2) {
    throw ArgumentError.value(
      pair,
      'altBrackets',
      'must be exactly two characters',
    );
  }
}
