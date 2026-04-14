import 'package:chord_pro/src/ast/metadata.dart';
import 'package:chord_pro/src/ast/section.dart';
import 'package:chord_pro/src/directive/directive.dart';

/// A parsed ChordPro song.
class Song {
  /// Creates a new [Song].
  const Song({
    required this.metadata,
    this.directives = const [],
    this.sections = const [],
  });

  /// Structured metadata collected from the song's directives.
  final Metadata metadata;

  /// Sections in source order (loose text, verses, choruses, tabs, …).
  final List<Section> sections;

  /// All directives that belonged to this song, in source order.
  ///
  /// Preserved losslessly so future stages can render or re-emit the
  /// document without re-parsing.
  final List<Directive> directives;
}
