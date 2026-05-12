import 'package:chord_pro/src/ast/transpose_qualifier.dart';
import 'package:chord_pro/src/directive/directive.dart';

/// Structured metadata collected from a song's directives.
///
/// Every field has a safe empty default so callers can read without
/// null-guarding. Unknown or user-defined metadata lands in [other].
class Metadata {
  /// Creates a new [Metadata].
  const Metadata({
    this.titles = const [],
    this.sortTitles = const [],
    this.subtitles = const [],
    this.artists = const [],
    this.sortArtists = const [],
    this.composers = const [],
    this.lyricists = const [],
    this.arrangers = const [],
    this.copyright,
    this.album,
    this.year,
    this.keys = const [],
    this.times = const [],
    this.tempos = const [],
    this.duration,
    this.capo,
    this.transpose,
    this.transposeQualifier = TransposeQualifier.none,
    this.columns,
    this.tags = const [],
    this.other = const {},
  });

  /// Titles (`{title}` / `{t}`). A song may declare more than one.
  final List<String> titles;

  /// Sort titles (`{sorttitle}`).
  ///
  /// Per `directives-sorttitle/`, when a song has multiple titles there
  /// must be one `sorttitle` for each `title`, in matching source order.
  final List<String> sortTitles;

  /// Subtitles (`{subtitle}` / `{st}`).
  final List<String> subtitles;

  /// Performing artists (`{artist}`).
  final List<String> artists;

  /// Sort artists (`{sortartist}`).
  ///
  /// Per `directives-sortartist/`, when a song has multiple artists
  /// there must be one `sortartist` for each `artist`, in matching
  /// source order.
  final List<String> sortArtists;

  /// Composers (`{composer}`).
  final List<String> composers;

  /// Lyricists (`{lyricist}`).
  final List<String> lyricists;

  /// Arrangers (`{arranger}`).
  final List<String> arrangers;

  /// Copyright string, stored verbatim.
  final String? copyright;

  /// Album name.
  final String? album;

  /// Publication year.
  final int? year;

  /// Song keys (`{key}`). Multi-valued per `directives-key/`: each
  /// `{key}` declaration applies from its position onward. The first
  /// entry is the song's primary key; later entries are modulations.
  final List<String> keys;

  /// Time signatures (`{time}`). Multi-valued per `directives-time/`:
  /// each `{time}` declaration applies from its position onward.
  final List<String> times;

  /// Tempos in BPM (`{tempo}`). Multi-valued per `directives-tempo/`:
  /// each `{tempo}` declaration applies from its position onward.
  final List<int> tempos;

  /// Duration string (spec-free; e.g. `"3:42"`).
  final String? duration;

  /// Capo fret number.
  final int? capo;

  /// Convenience accessor for the first `{sorttitle}`.
  String? get sortTitle => sortTitles.isEmpty ? null : sortTitles.first;

  /// Convenience accessor for the first `{sortartist}`.
  String? get sortArtist => sortArtists.isEmpty ? null : sortArtists.first;

  /// Convenience accessor for the primary `{key}` (first declared).
  String? get key => keys.isEmpty ? null : keys.first;

  /// Convenience accessor for the primary `{time}` (first declared).
  String? get time => times.isEmpty ? null : times.first;

  /// Convenience accessor for the primary `{tempo}` (first declared).
  int? get tempo => tempos.isEmpty ? null : tempos.first;

  /// Transposition in semitones (`{transpose: N}`).
  ///
  /// Captures the value declared in source. Use `Song.transposed` to
  /// apply it to chord tokens.
  final int? transpose;

  /// Optional postfix qualifier on the transpose value (`s`/`f`/`k`
  /// or their aliases `#`/`b`/`♯`/`♭`).
  ///
  /// Defaults to [TransposeQualifier.none] when no qualifier is
  /// present. The `k` qualifier was added in ChordPro 6.100.
  final TransposeQualifier transposeQualifier;

  /// Number of layout columns (`{columns: N}` / `{col: N}`).
  final int? columns;

  /// Free-form tags (`{tag}`), preserved in source order.
  final List<String> tags;

  /// Unknown / custom metadata. Keys are lowercased.
  final Map<String, List<String>> other;

  /// Whether no metadata fields were populated.
  bool get isEmpty =>
      titles.isEmpty &&
      sortTitles.isEmpty &&
      subtitles.isEmpty &&
      artists.isEmpty &&
      sortArtists.isEmpty &&
      composers.isEmpty &&
      lyricists.isEmpty &&
      arrangers.isEmpty &&
      copyright == null &&
      album == null &&
      year == null &&
      keys.isEmpty &&
      times.isEmpty &&
      tempos.isEmpty &&
      duration == null &&
      capo == null &&
      transpose == null &&
      columns == null &&
      tags.isEmpty &&
      other.isEmpty;
}

/// Known metadata directive names plus their short-form aliases.
///
/// Kept internal — callers read [Metadata] fields instead.
const Map<String, String> _metadataAliases = {
  't': 'title',
  'st': 'subtitle',
  'col': 'columns',
};

const Set<String> _listMetadataNames = {
  'title',
  'subtitle',
  'artist',
  'composer',
  'lyricist',
  'arranger',
  'tag',
};

const Set<String> _intMetadataNames = {
  'year',
  'tempo',
  'capo',
  'transpose',
  'columns',
};

// Names auto-generated by the renderer at runtime. They cannot be set
// from user `{meta:}` directives — collisions are silently dropped so
// downstream renderers see only their own derived values.
//
// Reference: `Song.pm` lines 2117–2164 (auto-generated meta) plus
// `chordpro-configuration-format-strings/` (full reserved namespace).
const Set<String> _reservedAutogeneratedNames = {
  // Key / transposition.
  '_key',
  'key.print',
  'key.sound',
  'key_actual',
  'key_from',
  // Runtime build identity.
  'chordpro',
  'chordpro.version',
  'chordpro.songsource',
  'today',
  // Layout / page.
  'page',
  'pageno',
  'pages',
  'pagerange',
  'page.class',
  'page.side',
  // Song / index / chord stats.
  'songindex',
  'songsource',
  'chords',
  'numchords',
  // Instrument / user (auto-populated from the active config).
  'instrument',
  'instrument.type',
  'instrument.description',
  'tuning',
  'user',
  'user.name',
  'user.fullname',
};

// `{transpose: N}` accepts an optional postfix qualifier per the
// reference parser (`Transpose.pm:114`):
// `^([-+]?\d+)(?:([s#♯])|([fb♭])|([k]))?$`. We accept `s`/`f`/`k` plus
// their `#`/`b` ASCII aliases and the `♯`/`♭` glyph aliases.
final RegExp _transposeRe =
    RegExp(r'^([-+]?\d+)([sfk#b♯♭])?$', caseSensitive: false);

const Set<String> _scalarMetadataNames = {
  'copyright',
  'album',
  'duration',
};

/// Multi-valued positional metadata (lists in source order).
///
/// - `sorttitle` / `sortartist` per `directives-sorttitle/` and
///   `directives-sortartist/`: one entry per `title` / `artist`.
/// - `key` / `time` / `tempo` per `directives-key/` etc.: each
///   declaration applies from its position onward.
const Set<String> _multiValuedMetadataNames = {
  'sorttitle',
  'sortartist',
  'key',
  'time',
};

/// Reduces a stream of [Directive]s into a typed [Metadata].
///
/// Directives whose name is not recognised as metadata are ignored; the
/// assembler is responsible for passing only metadata-bearing directives
/// (including those desugared from `{meta: key value}`).
///
/// Directives with a selector (`{title-guitar: …}`) are skipped by
/// default — callers that know which selectors are active should filter
/// the input stream before calling this function. When [includeSelected]
/// is non-empty, directives whose selector is in that set (for the
/// right polarity) are merged in as if bare.
Metadata reduceMetadata(
  Iterable<Directive> directives, {
  Set<String> includeSelected = const {},
}) {
  final titles = <String>[];
  final sortTitles = <String>[];
  final subtitles = <String>[];
  final artists = <String>[];
  final sortArtists = <String>[];
  final composers = <String>[];
  final lyricists = <String>[];
  final arrangers = <String>[];
  final tags = <String>[];
  final keys = <String>[];
  final times = <String>[];
  final tempos = <int>[];
  final other = <String, List<String>>{};
  String? copyright;
  String? album;
  int? year;
  String? duration;
  int? capo;
  int? transpose;
  var transposeQualifier = TransposeQualifier.none;
  int? columns;

  for (final d in directives) {
    if (d.isCustomExtension) continue;
    if (d.selector != null) {
      final active = includeSelected.contains(d.selector);
      final applies = switch (d.polarity) {
        Polarity.positive => active,
        Polarity.negative => !active,
        Polarity.none => true,
      };
      if (!applies) continue;
    }
    final name = _metadataAliases[d.name] ?? d.name;
    final value = d.value;
    if (value == null) continue;

    if (_listMetadataNames.contains(name)) {
      switch (name) {
        case 'title':
          titles.add(value);
        case 'subtitle':
          subtitles.add(value);
        case 'artist':
          artists.add(value);
        case 'composer':
          composers.add(value);
        case 'lyricist':
          lyricists.add(value);
        case 'arranger':
          arrangers.add(value);
        case 'tag':
          tags.add(value);
      }
    } else if (_multiValuedMetadataNames.contains(name)) {
      switch (name) {
        case 'sorttitle':
          sortTitles.add(value);
        case 'sortartist':
          sortArtists.add(value);
        case 'key':
          keys.add(value);
        case 'time':
          times.add(value);
      }
    } else if (_scalarMetadataNames.contains(name)) {
      switch (name) {
        case 'copyright':
          copyright = value;
        case 'album':
          album = value;
        case 'duration':
          duration = value;
      }
    } else if (_intMetadataNames.contains(name)) {
      if (name == 'transpose') {
        final m = _transposeRe.firstMatch(value);
        if (m == null) continue;
        transpose = int.parse(m.group(1)!);
        final tag = m.group(2)?.toLowerCase();
        transposeQualifier = switch (tag) {
          's' || '#' || '♯' => TransposeQualifier.sharps,
          'f' || 'b' || '♭' => TransposeQualifier.flats,
          'k' => TransposeQualifier.followKey,
          _ => TransposeQualifier.none,
        };
        continue;
      }
      final n = int.tryParse(value);
      if (n == null) continue;
      switch (name) {
        case 'year':
          year = n;
        case 'tempo':
          tempos.add(n);
        case 'capo':
          capo = n;
        case 'columns':
          columns = n;
      }
    } else if (!_reservedAutogeneratedNames.contains(name)) {
      (other[name] ??= []).add(value);
    }
  }

  return Metadata(
    titles: List.unmodifiable(titles),
    sortTitles: List.unmodifiable(sortTitles),
    subtitles: List.unmodifiable(subtitles),
    artists: List.unmodifiable(artists),
    sortArtists: List.unmodifiable(sortArtists),
    composers: List.unmodifiable(composers),
    lyricists: List.unmodifiable(lyricists),
    arrangers: List.unmodifiable(arrangers),
    copyright: copyright,
    album: album,
    year: year,
    keys: List.unmodifiable(keys),
    times: List.unmodifiable(times),
    tempos: List.unmodifiable(tempos),
    duration: duration,
    capo: capo,
    transpose: transpose,
    transposeQualifier: transposeQualifier,
    columns: columns,
    tags: List.unmodifiable(tags),
    other: Map.unmodifiable(
      {
        for (final e in other.entries)
          e.key: List<String>.unmodifiable(e.value),
      },
    ),
  );
}
