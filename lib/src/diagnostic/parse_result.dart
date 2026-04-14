import 'package:chord_pro/src/ast/song.dart';
import 'package:chord_pro/src/diagnostic/diagnostic.dart';

/// The outcome of parsing a ChordPro document.
class ParseResult {
  /// Creates a new [ParseResult].
  const ParseResult({
    required this.songs,
    this.diagnostics = const [],
  });

  /// All songs found in the document, split on `{new_song}` / `{ns}`.
  ///
  /// A document with no body still produces a single (empty) song so
  /// callers can always index `[0]`.
  final List<Song> songs;

  /// Diagnostics accumulated while parsing.
  final List<Diagnostic> diagnostics;
}
