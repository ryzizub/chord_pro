import 'package:chord_pro/src/assembler/assembler.dart';
import 'package:chord_pro/src/ast/song.dart';
import 'package:chord_pro/src/diagnostic/parse_result.dart';

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
  /// set to a two-character pair (e.g. `«»`), those characters are
  /// rewritten to `[` / `]` before parsing.
  ///
  /// [notesMode] mirrors the `settings.notes` configuration option: when
  /// `true`, lowercase `a`–`g` are accepted as letter-system chord roots.
  ///
  /// [strict] mirrors `settings.strict`: when `true`, a warning is emitted
  /// for each song that lacks a `{key}` directive. Defaults to `false`,
  /// consistent with the ChordPro 6.100 change that made forgiving the
  /// built-in default.
  static ParseResult parse(
    String source, {
    Set<String> selectors = const {},
    String? altBrackets,
    bool notesMode = false,
    bool strict = false,
  }) {
    final input = _applyAltBrackets(source, altBrackets);
    return assemble(
      input,
      selectors: selectors,
      notesMode: notesMode,
      strict: strict,
    );
  }

  /// Convenience wrapper that returns the first song of [source].
  static Song parseSong(
    String source, {
    Set<String> selectors = const {},
    String? altBrackets,
    bool notesMode = false,
    bool strict = false,
  }) =>
      parse(
        source,
        selectors: selectors,
        altBrackets: altBrackets,
        notesMode: notesMode,
        strict: strict,
      ).songs.first;
}

String _applyAltBrackets(String source, String? pair) {
  if (pair == null) return source;
  final runes = pair.runes.toList(growable: false);
  if (runes.length != 2) {
    throw ArgumentError.value(
      pair,
      'altBrackets',
      'must be exactly two characters',
    );
  }
  final open = String.fromCharCode(runes[0]);
  final close = String.fromCharCode(runes[1]);
  return source.replaceAll(open, '[').replaceAll(close, ']');
}
