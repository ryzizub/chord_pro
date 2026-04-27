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
  static ParseResult parse(
    String source, {
    Set<String> selectors = const {},
  }) =>
      assemble(source, selectors: selectors);

  /// Convenience wrapper that returns the first song of [source].
  static Song parseSong(
    String source, {
    Set<String> selectors = const {},
  }) =>
      parse(source, selectors: selectors).songs.first;
}
