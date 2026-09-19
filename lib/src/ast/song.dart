import 'package:chord_pro/src/ast/diagrams_setting.dart';
import 'package:chord_pro/src/ast/formatting.dart';
import 'package:chord_pro/src/ast/line.dart';
import 'package:chord_pro/src/ast/metadata.dart';
import 'package:chord_pro/src/ast/section.dart';
import 'package:chord_pro/src/ast/titles_alignment.dart';
import 'package:chord_pro/src/chord/chord.dart';
import 'package:chord_pro/src/chord/chord_definition.dart';
import 'package:chord_pro/src/directive/directive.dart';
import 'package:chord_pro/src/inline/inline_token.dart';
import 'package:chord_pro/src/util/equality.dart';

/// A parsed ChordPro song.
class Song {
  /// Creates a new [Song].
  const Song({
    required this.metadata,
    this.directives = const [],
    this.sections = const [],
    this.chordDefinitions = const [],
    this.formatting = const FormattingSettings(),
    this.tocSuppressed = false,
    this.titlesAlignment,
    this.diagrams,
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

  /// `true` when the song should be omitted from the table of
  /// contents (set by the preceding `{ns toc=no}` /
  /// `{new_song toc=false|0}`, ChordPro 6.040). Always `false` for
  /// the first song in a document.
  final bool tocSuppressed;

  /// Set by the `{titles}` directive (legacy/deprecated alignment
  /// hint for the title block). `null` when no `{titles}` directive
  /// was seen or its value did not match `left|center|right`.
  final TitlesAlignment? titlesAlignment;

  /// Last-seen `{diagrams}` (or `{g}` alias) setting.
  ///
  /// `null` when the song has no `{diagrams}` directive — callers
  /// should treat that as "use the renderer's default".
  final DiagramsSetting? diagrams;

  /// Directives in the `x_*` custom namespace, in source order.
  Iterable<Directive> get customExtensions =>
      directives.where((d) => d.isCustomExtension);

  /// Returns a new [Song] with every chord transposed by [semitones].
  ///
  /// Letter chords are remapped through the chromatic scale; chords in
  /// other notations (Nashville, Roman) are key-agnostic and pass
  /// through unchanged. The song key in [Metadata.key] is also remapped
  /// when it points at a recognised root.
  ///
  /// When [forceCommonKeys] is `true` (mirrors the `keys.force-common`
  /// ChordPro 6.100 configuration option), roots that would produce a key
  /// signature with more than 5 accidentals are substituted with their
  /// enharmonic equivalents: `C#`→`Db`, `D#`→`Eb`, `G#`→`Ab`, `A#`→`Bb`.
  ///
  /// Every letter chord is respelled according to [accidentals], so this
  /// is a normalisation pass as well as a transposition: `transposed(0,
  /// accidentals: AccidentalPreference.flats)` respells the song in flats
  /// without changing its pitch, and `transposed(12)` respells at the
  /// same pitch class.
  Song transposed(
    int semitones, {
    AccidentalPreference accidentals = AccidentalPreference.sharps,
    bool forceCommonKeys = false,
  }) {
    final newSections = sections
        .map(
          (s) => Section(
            kind: s.kind,
            label: s.label,
            customKind: s.customKind,
            isChorusRecall: s.isChorusRecall,
            attributes: s.attributes,
            span: s.span,
            lines: List.unmodifiable(
              s.lines.map(
                (line) => _transposeLine(
                  line,
                  semitones,
                  accidentals,
                  forceCommonKeys: forceCommonKeys,
                ),
              ),
            ),
          ),
        )
        .toList(growable: false);

    final newKeys = metadata.keys
        .map(
          (k) =>
              _transposeKey(
                k,
                semitones,
                accidentals,
                forceCommonKeys: forceCommonKeys,
              ) ??
              k,
        )
        .toList(growable: false);

    return Song(
      metadata: Metadata(
        titles: metadata.titles,
        sortTitles: metadata.sortTitles,
        subtitles: metadata.subtitles,
        artists: metadata.artists,
        sortArtists: metadata.sortArtists,
        composers: metadata.composers,
        lyricists: metadata.lyricists,
        arrangers: metadata.arrangers,
        copyright: metadata.copyright,
        album: metadata.album,
        year: metadata.year,
        keys: List.unmodifiable(newKeys),
        times: metadata.times,
        tempos: metadata.tempos,
        duration: metadata.duration,
        capo: metadata.capo,
        transpose: 0,
        transposeQualifier: metadata.transposeQualifier,
        columns: metadata.columns,
        tags: metadata.tags,
        other: metadata.other,
      ),
      directives: directives,
      sections: List.unmodifiable(newSections),
      chordDefinitions: chordDefinitions,
      formatting: formatting,
      tocSuppressed: tocSuppressed,
      titlesAlignment: titlesAlignment,
      diagrams: diagrams,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          other.metadata == metadata &&
          listEquals(other.sections, sections) &&
          listEquals(other.chordDefinitions, chordDefinitions) &&
          listEquals(other.directives, directives) &&
          other.formatting == formatting &&
          other.tocSuppressed == tocSuppressed &&
          other.titlesAlignment == titlesAlignment &&
          other.diagrams == diagrams;

  @override
  int get hashCode => Object.hash(
        metadata,
        Object.hashAll(sections),
        Object.hashAll(chordDefinitions),
        Object.hashAll(directives),
        formatting,
        tocSuppressed,
        titlesAlignment,
        diagrams,
      );
}

/// Transposes a metadata key spelling.
///
/// Letter-system spellings (`G`, `Am`, `F#m7`) are remapped through the
/// chromatic scale, preserving any quality/extension suffix. Unrecognised
/// or non-letter spellings (e.g. Nashville/Roman keys, free text) are
/// returned verbatim so callers don't lose the original value.
String? _transposeKey(
  String? key,
  int semitones,
  AccidentalPreference accidentals, {
  bool forceCommonKeys = false,
}) {
  if (key == null) return null;
  final chord = Chord.tryParse(key);
  if (chord == null || chord.system != ChordSystem.letter) return key;
  return chord
      .transpose(
        semitones,
        accidentals: accidentals,
        forceCommonKeys: forceCommonKeys,
      )
      .raw;
}

Line _transposeLine(
  Line line,
  int semitones,
  AccidentalPreference accidentals, {
  bool forceCommonKeys = false,
}) {
  if (line.kind != LineKind.structured) return line;
  final newTokens = <InlineToken>[];
  for (final token in line.tokens) {
    if (token is ChordToken && token.chord != null) {
      final transposed = token.chord!.transpose(
        semitones,
        accidentals: accidentals,
        forceCommonKeys: forceCommonKeys,
      );
      newTokens.add(
        ChordToken(raw: transposed.raw, chord: transposed, span: token.span),
      );
    } else {
      newTokens.add(token);
    }
  }
  return Line(tokens: List.unmodifiable(newTokens), span: line.span);
}
