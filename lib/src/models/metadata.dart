import 'package:chord_pro/src/models/directive.dart';
import 'package:collection/collection.dart';

/// The entry point of the Metada
class Metadata with DirectiveMixin<Metadata> {
  /// Holds info the song like [title] etc.
  Metadata({
    this.title,
  });

  /// Creates instance of [Metadata] from created map of already
  /// parsed content of Chordpro
  factory Metadata.fromDirectiveMap(Map<String, List<String>> map) {
    final title = _retrieveMetaValue(map, ['title', 't']);

    return Metadata(
      title: title,
    );
  }

  /// The title of the song
  final String? title;

  @override
  bool isEmpty() {
    return [
      title,
    ].nonNulls.isEmpty;
  }
}

/// Accounts for retrieving value even when it's under {meta: key ....}
String? _retrieveMetaValue(Map<String, List<String>> map, List<String> keys) {
  for (final key in keys) {
    if (map['meta'] != null &&
        map['meta']!.isNotEmpty &&
        map['meta']!.firstWhereOrNull((one) => one.trim().startsWith(key)) !=
            null) {
      return map['meta']!
          .firstWhere((one) => one.trim().startsWith('$key '))
          .replaceFirst(key, '')
          .trimLeft();
    } else if (map[key] != null && map[key]!.isNotEmpty) {
      return map[key]!.first;
    }
  }
  return null;
}
