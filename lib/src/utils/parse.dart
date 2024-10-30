import 'package:chord_pro/src/utils/constants.dart';

/// Retrieves key-value directives from the song
Map<String, List<String>> directiveParse(String chordProText) {
  final matches = directiveRegExp.allMatches(chordProText);

  final directives = <String, List<String>>{};

  for (final match in matches) {
    final key = match.group(1)!.trim().toLowerCase();
    final value = match.group(2)?.trim();

    if (directives.containsKey(key)) {
      directives[key]!.add(value ?? '');
    } else {
      directives[key] = [value ?? ''];
    }
  }

  return directives;
}
