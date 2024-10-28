import 'package:chord_pro/src/utils/constants.dart';

/// Retrieves key-value directives from the song
Map<String, String?> directiveParse(String chordProText) {
  final matches = directiveRegExp.allMatches(chordProText);

  final pairs = matches.map(
    (match) {
      if (match.groupCount == 0) {
        return null;
      }

      final key = match.group(1)!.trim().toLowerCase();

      if (match.groupCount == 1) {
        return MapEntry(key, null);
      }

      final value = match.group(2)!.trim();

      return MapEntry(key, value);
    },
  ).nonNulls;

  return Map.fromEntries(pairs);
}
