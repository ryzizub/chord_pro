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
  static ParseResult parse(String source) => assemble(source);

  /// Convenience wrapper that returns the first song of [source].
  static Song parseSong(String source) => parse(source).songs.first;
}
