import 'package:chord_pro/src/directive/directive.dart';

/// Structured metadata collected from a song's directives.
///
/// Every field has a safe empty default so callers can read without
/// null-guarding. Unknown or user-defined metadata lands in [other].
class Metadata {
  /// Creates a new [Metadata].
  const Metadata({
    this.titles = const [],
    this.sortTitle,
    this.subtitles = const [],
    this.artists = const [],
    this.sortArtist,
    this.composers = const [],
    this.lyricists = const [],
    this.copyright,
    this.album,
    this.year,
    this.key,
    this.time,
    this.tempo,
    this.duration,
    this.capo,
    this.transpose,
    this.columns,
    this.tags = const [],
    this.other = const {},
  });

  /// Titles (`{title}` / `{t}`). A song may declare more than one.
  final List<String> titles;

  /// Sort title (`{sorttitle}`).
  final String? sortTitle;

  /// Subtitles (`{subtitle}` / `{st}`).
  final List<String> subtitles;

  /// Performing artists (`{artist}`).
  final List<String> artists;

  /// Sort artist (`{sortartist}`).
  final String? sortArtist;

  /// Composers (`{composer}`).
  final List<String> composers;

  /// Lyricists (`{lyricist}`).
  final List<String> lyricists;

  /// Copyright string, stored verbatim.
  final String? copyright;

  /// Album name.
  final String? album;

  /// Publication year.
  final int? year;

  /// Song key (e.g. `"C"`, `"Am"`).
  final String? key;

  /// Time signature (e.g. `"4/4"`).
  final String? time;

  /// Tempo in BPM.
  final int? tempo;

  /// Duration string (spec-free; e.g. `"3:42"`).
  final String? duration;

  /// Capo fret number.
  final int? capo;

  /// Transposition in semitones (`{transpose: N}`).
  ///
  /// Captures the value declared in source. Use `Song.transposed` to
  /// apply it to chord tokens.
  final int? transpose;

  /// Number of layout columns (`{columns: N}` / `{col: N}`).
  final int? columns;

  /// Free-form tags (`{tag}`), preserved in source order.
  final List<String> tags;

  /// Unknown / custom metadata. Keys are lowercased.
  final Map<String, List<String>> other;

  /// Whether no metadata fields were populated.
  bool get isEmpty =>
      titles.isEmpty &&
      sortTitle == null &&
      subtitles.isEmpty &&
      artists.isEmpty &&
      sortArtist == null &&
      composers.isEmpty &&
      lyricists.isEmpty &&
      copyright == null &&
      album == null &&
      year == null &&
      key == null &&
      time == null &&
      tempo == null &&
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
  'tag',
};

const Set<String> _intMetadataNames = {
  'year',
  'tempo',
  'capo',
  'transpose',
  'columns',
};

const Set<String> _scalarMetadataNames = {
  'sorttitle',
  'sortartist',
  'copyright',
  'album',
  'key',
  'time',
  'duration',
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
  final subtitles = <String>[];
  final artists = <String>[];
  final composers = <String>[];
  final lyricists = <String>[];
  final tags = <String>[];
  final other = <String, List<String>>{};
  String? sortTitle;
  String? sortArtist;
  String? copyright;
  String? album;
  int? year;
  String? key;
  String? time;
  int? tempo;
  String? duration;
  int? capo;
  int? transpose;
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
        case 'tag':
          tags.add(value);
      }
    } else if (_scalarMetadataNames.contains(name)) {
      switch (name) {
        case 'sorttitle':
          sortTitle = value;
        case 'sortartist':
          sortArtist = value;
        case 'copyright':
          copyright = value;
        case 'album':
          album = value;
        case 'key':
          key = value;
        case 'time':
          time = value;
        case 'duration':
          duration = value;
      }
    } else if (_intMetadataNames.contains(name)) {
      final n = int.tryParse(value);
      if (n == null) continue;
      switch (name) {
        case 'year':
          year = n;
        case 'tempo':
          tempo = n;
        case 'capo':
          capo = n;
        case 'transpose':
          transpose = n;
        case 'columns':
          columns = n;
      }
    } else {
      (other[name] ??= []).add(value);
    }
  }

  return Metadata(
    titles: titles,
    sortTitle: sortTitle,
    subtitles: subtitles,
    artists: artists,
    sortArtist: sortArtist,
    composers: composers,
    lyricists: lyricists,
    copyright: copyright,
    album: album,
    year: year,
    key: key,
    time: time,
    tempo: tempo,
    duration: duration,
    capo: capo,
    transpose: transpose,
    columns: columns,
    tags: tags,
    other: other,
  );
}
