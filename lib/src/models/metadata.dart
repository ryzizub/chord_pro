import 'package:chord_pro/src/models/copyright.dart';
import 'package:chord_pro/src/models/directive.dart';
import 'package:collection/collection.dart';

/// The entry point of the [Metadata]
class Metadata with DirectiveMixin<Metadata> {
  /// Holds info the song like [title] etc.
  Metadata({
    this.title,
    this.sortTitle,
    this.subtitle,
    this.artist,
    this.composer,
    this.lyricist,
    this.copyright,
    this.album,
    this.year,
    this.key,
    this.time,
    this.tempo,
    this.duration,
    this.capo,
    this.other,
  });

  /// Creates instance of [Metadata] from created map of already
  /// parsed content of Chordpro
  factory Metadata.fromDirectiveMap(Map<String, List<String>> map) {
    final title = _retrieveMetaValue(map, ['title', 't']);
    final sortTitle = _retrieveMetaValue(map, ['sorttitle'])?.firstOrNull;
    final subtitle = _retrieveMetaValue(map, ['subtitle'])?.firstOrNull;
    final artist = _retrieveMetaValue(map, ['artist']);
    final composer = _retrieveMetaValue(map, ['composer']);
    final lyricist = _retrieveMetaValue(map, ['lyricist']);

    final copyrightContent = _retrieveMetaValue(map, ['copyright']);
    final copyright = copyrightContent != null
        ? Copyright.fromString(copyrightContent.first)
        : null;

    final album = _retrieveMetaValue(map, ['album'])?.firstOrNull;
    final year =
        int.tryParse(_retrieveMetaValue(map, ['year'])?.firstOrNull ?? '');
    final key = _retrieveMetaValue(map, ['key'])?.firstOrNull;
    final time = _retrieveMetaValue(map, ['time'])?.firstOrNull;
    final tempo =
        int.tryParse(_retrieveMetaValue(map, ['tempo'])?.firstOrNull ?? '');
    final duration = _retrieveMetaValue(map, ['duration'])?.firstOrNull;
    final capo =
        int.tryParse(_retrieveMetaValue(map, ['capo'])?.firstOrNull ?? '');

    final parsedKeys = {
      'title',
      't',
      'sorttitle',
      'subtitle',
      'artist',
      'composer',
      'lyricist',
      'copyright',
      'album',
      'year',
      'key',
      'time',
      'tempo',
      'duration',
      'capo',
    };

    final otherNotParsedMeta = Map<String, String>.fromEntries(
      map['meta']?.where((one) {
            final key = one.trim().split(' ').first;
            return !parsedKeys.contains(key);
          }).map((one) {
            final parts = one.trim().split(' ');
            return MapEntry(parts.first, parts.sublist(1).join(' '));
          }) ??
          [],
    );

    return Metadata(
      title: title,
      sortTitle: sortTitle,
      subtitle: subtitle,
      artist: artist,
      composer: composer,
      lyricist: lyricist,
      copyright: copyright,
      album: album,
      year: year,
      key: key,
      time: time,
      tempo: tempo,
      duration: duration,
      capo: capo,
      other: otherNotParsedMeta,
    );
  }

  /// The title of the song
  final List<String>? title;

  /// The sorting title of the song
  final String? sortTitle;

  /// The subtitle of the song
  final String? subtitle;

  /// The artist behind the song
  final List<String>? artist;

  /// The composer behind the song
  final List<String>? composer;

  /// The composer behind the song
  final List<String>? lyricist;

  /// The copyright of the song
  final Copyright? copyright;

  /// The album that the song belongs to
  final String? album;

  /// The year of the song
  final int? year;

  /// The key of the song
  final String? key;

  /// The time signature of the song
  final String? time;

  /// The tempo of the song
  final int? tempo;

  /// The duration of the song
  final String? duration;

  /// The capo of the song
  final int? capo;

  /// The other metadata of the song
  final Map<String, String>? other;

  @override
  bool isEmpty() {
    return [
      title?.isEmpty,
      sortTitle,
      subtitle,
      artist?.isEmpty,
      composer?.isEmpty,
      lyricist?.isEmpty,
      copyright,
      album,
      year,
      key,
      time,
      tempo,
      duration,
      capo,
      other,
    ].nonNulls.isEmpty;
  }
}

/// Accounts for retrieving value even when it's under {meta: key ....}
List<String>? _retrieveMetaValue(
  Map<String, List<String>> map,
  List<String> keys,
) {
  for (final key in keys) {
    if (map['meta'] != null &&
        map['meta']!.isNotEmpty &&
        map['meta']!.firstWhereOrNull((one) => one.trim().startsWith(key)) !=
            null) {
      return map['meta']!
          .where((one) => one.trim().startsWith('$key '))
          .map((one) => one.replaceFirst(key, '').trimLeft())
          .toList();
    } else if (map[key] != null && map[key]!.isNotEmpty) {
      return map[key];
    }
  }
  return null;
}
