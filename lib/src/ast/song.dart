import 'package:chord_pro/src/ast/metadata.dart';
import 'package:chord_pro/src/directive/directive.dart';

/// A parsed ChordPro song.
///
/// Phase 1 of the library exposes metadata and the raw directive stream
/// only; later phases add sections, lines, and chord definitions.
class Song {
  /// Creates a new [Song].
  const Song({
    required this.metadata,
    this.directives = const [],
  });

  /// Structured metadata collected from the song's directives.
  final Metadata metadata;

  /// All directives that belonged to this song, in source order.
  ///
  /// Preserved losslessly so future stages can render or re-emit the
  /// document without re-parsing.
  final List<Directive> directives;
}
