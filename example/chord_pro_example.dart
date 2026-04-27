// Example file prints to stdout to demonstrate parser output.
// ignore_for_file: avoid_print

import 'package:chord_pro/chord_pro.dart';

const _source = '''
{title: Knockin' on Heaven's Door}
{artist: Bob Dylan}
{key: G}
{tempo: 68}

{start_of_verse: Verse 1}
[G]Mama, take this [D]badge off of [Am]me
[G]I can't use it [D]any[C]more
{end_of_verse}

{start_of_chorus}
[G]Knock, knock, [D]knockin' on [Am]heaven's door
{end_of_chorus}
''';

void main() {
  // Parse a ChordPro document. Multi-song documents (split on {new_song})
  // are returned in `result.songs`; diagnostics list any problems.
  final result = ChordPro.parse(_source);
  final song = result.songs.single;

  print('Title:  ${song.metadata.titles.firstOrNull}');
  print('Artist: ${song.metadata.artists.firstOrNull}');
  print('Key:    ${song.metadata.key}');
  print('Tempo:  ${song.metadata.tempo}');
  print('Sections: ${song.sections.length}');

  // Walk every section and print chords + lyrics.
  for (final section in song.sections) {
    print('\n[${section.kind.name}] ${section.label ?? ''}');
    for (final line in section.lines) {
      switch (line.kind) {
        case LineKind.structured:
          final buffer = StringBuffer();
          for (final token in line.tokens) {
            if (token is ChordToken) {
              buffer.write('[${token.raw}]');
            } else if (token is TextToken) {
              buffer.write(token.text);
            }
          }
          print('  $buffer');
        case LineKind.comment:
          print('  // ${line.comment}');
        case LineKind.image:
          print('  image: ${line.image?.src}');
        case LineKind.layoutBreak:
          print('  break: ${line.layoutBreak}');
        case LineKind.verbatim:
          print('  ${line.verbatim}');
      }
    }
  }

  // Transpose the whole song up two semitones.
  final transposed = ChordPro.parseSong(_source).transposed(2);
  print('\nTransposed key: ${transposed.metadata.key}');
}
