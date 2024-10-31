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
  });

  /// Creates instance of [Metadata] from created map of already
  /// parsed content of Chordpro
  factory Metadata.fromDirectiveMap(Map<String, List<String>> map) {
    final title = _retrieveMetaValue(map, ['title', 't']);
    final sortTitle = _retrieveMetaValue(map, ['sorttitle'])?.firstOrNull;
    final subtitle = _retrieveMetaValue(map, ['sorttitle'])?.firstOrNull;
    final artist = _retrieveMetaValue(map, ['artist']);
    final composer = _retrieveMetaValue(map, ['composer']);
    final lyricist = _retrieveMetaValue(map, ['lyricist']);

    final copyrightContent = _retrieveMetaValue(map, ['copyright']);
    final copyright = copyrightContent != null
        ? Copyright.fromString(copyrightContent.first)
        : null;

    return Metadata(
      title: title,
      sortTitle: sortTitle,
      subtitle: subtitle,
      artist: artist,
      composer: composer,
      lyricist: lyricist,
      copyright: copyright,
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
