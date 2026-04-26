import 'package:chord_pro/src/ast/formatting.dart';
import 'package:chord_pro/src/ast/line.dart';
import 'package:chord_pro/src/ast/metadata.dart';
import 'package:chord_pro/src/ast/section.dart';
import 'package:chord_pro/src/chord/chord.dart';
import 'package:chord_pro/src/chord/chord_definition.dart';
import 'package:chord_pro/src/directive/directive.dart';
import 'package:chord_pro/src/inline/inline_token.dart';

/// A parsed ChordPro song.
class Song {
  /// Creates a new [Song].
  const Song({
    required this.metadata,
    this.directives = const [],
    this.sections = const [],
    this.chordDefinitions = const [],
    this.formatting = const FormattingSettings(),
  });

  /// Structured metadata collected from the song's directives.
  final Metadata metadata;

  /// Sections in source order (loose text, verses, choruses, tabs, …).
  final List<Section> sections;

  /// Chord definitions declared via `{define}` / `{chord}`.
  final List<ChordDefinition> chordDefinitions;

  /// All directives that belonged to this song, in source order.
  ///
  /// Preserved losslessly so future stages can render or re-emit the
  /// document without re-parsing.
  final List<Directive> directives;

  /// Document-wide font/size/colour settings.
  final FormattingSettings formatting;

  /// Directives in the `x_*` custom namespace, in source order.
  Iterable<Directive> get customExtensions =>
      directives.where((d) => d.isCustomExtension);

  /// Returns a new [Song] with every chord transposed by [semitones].
  ///
  /// Letter chords are remapped through the chromatic scale; chords in
  /// other notations (Nashville, Roman) are key-agnostic and pass
  /// through unchanged. The song key in [Metadata.key] is also remapped
  /// when it points at a recognised root.
  Song transposed(
    int semitones, {
    AccidentalPreference accidentals = AccidentalPreference.sharps,
  }) {
    if (semitones % 12 == 0) return this;
    final newSections = sections
        .map(
          (s) => Section(
            kind: s.kind,
            label: s.label,
            customKind: s.customKind,
            isChorusRecall: s.isChorusRecall,
            span: s.span,
            lines: s.lines
                .map(
                  (line) => _transposeLine(line, semitones, accidentals),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    final newKey = metadata.key == null
        ? null
        : transposeRoot(metadata.key!, semitones, accidentals: accidentals) ??
            metadata.key;

    return Song(
      metadata: Metadata(
        titles: metadata.titles,
        sortTitle: metadata.sortTitle,
        subtitles: metadata.subtitles,
        artists: metadata.artists,
        sortArtist: metadata.sortArtist,
        composers: metadata.composers,
        lyricists: metadata.lyricists,
        copyright: metadata.copyright,
        album: metadata.album,
        year: metadata.year,
        key: newKey,
        time: metadata.time,
        tempo: metadata.tempo,
        duration: metadata.duration,
        capo: metadata.capo,
        transpose: 0,
        columns: metadata.columns,
        tags: metadata.tags,
        other: metadata.other,
      ),
      directives: directives,
      sections: newSections,
      chordDefinitions: chordDefinitions,
      formatting: formatting,
    );
  }
}

Line _transposeLine(
  Line line,
  int semitones,
  AccidentalPreference accidentals,
) {
  if (line.kind != LineKind.structured) return line;
  final newTokens = <InlineToken>[];
  for (final token in line.tokens) {
    if (token is ChordToken && token.chord != null) {
      final transposed = token.chord!.transpose(
        semitones,
        accidentals: accidentals,
      );
      newTokens.add(
        ChordToken(raw: transposed.raw, chord: transposed, span: token.span),
      );
    } else {
      newTokens.add(token);
    }
  }
  return Line(tokens: newTokens, span: line.span);
}
