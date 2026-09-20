import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Song.transposed', () {
    test('captures {transpose} directive as metadata', () {
      const source = '{transpose: 3}\n[C]hello';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.transpose, 3);
    });

    test('shifts every chord token in every section', () {
      const source = '''
{title: Demo}
{key: C}
[C]hello [G]world
{start_of_chorus}
[Am]chorus [F]line
{end_of_chorus}
''';
      final transposed = ChordPro.parseSong(source).transposed(2);
      final loose = transposed.sections.first;
      final chordRoots = loose.lines.first.tokens
          .whereType<ChordToken>()
          .map((c) => c.chord?.root)
          .toList();
      expect(chordRoots, ['D', 'A']);

      final chorus = transposed.sections.last;
      final chorusRoots = chorus.lines.first.tokens
          .whereType<ChordToken>()
          .map((c) => c.chord?.root)
          .toList();
      expect(chorusRoots, ['B', 'G']);
    });

    test('updates the song key', () {
      final song = ChordPro.parseSong('{key: G}\n[G]hi');
      expect(song.transposed(2).metadata.key, 'A');
    });

    test('zero-step transposition leaves the song equal', () {
      final song = ChordPro.parseSong('{key: G}\n[G]hi');
      final same = song.transposed(0);
      expect(same.metadata.key, 'G');
      expect(_chords(same), ['G']);
    });

    test('zero-step transposition respells to the requested accidentals', () {
      // `transposed` normalises spelling as well as pitch, so a zero-step
      // pass is how a caller asks for the song in flats.
      final song = ChordPro.parseSong('{key: C#}\n[C#]hi [D#m]there');
      final flat = song.transposed(0, accidentals: AccidentalPreference.flats);
      expect(_chords(flat), ['Db', 'Ebm']);
      expect(flat.metadata.key, 'Db');
    });

    test('an octave transposition keeps the pitch class', () {
      final song = ChordPro.parseSong('[G]hi');
      expect(_chords(song.transposed(12)), ['G']);
      expect(_chords(song.transposed(-12)), ['G']);
    });

    test('keeps section attributes', () {
      final song = ChordPro.parseSong(
        '{start_of_grid: 4x4}\n| [C] |\n{end_of_grid}',
      );
      final moved = song.transposed(2);
      expect(moved.sections.first.attributes, {'shape': '4x4'});
      expect(moved.sections.first.gridAttributes?.measures, 4);
      expect(moved.sections.first.gridAttributes?.beats, 4);
    });
  });
}

List<String> _chords(Song song) => [
      for (final section in song.sections)
        for (final line in section.lines)
          for (final token in line.tokens)
            if (token is ChordToken) token.raw,
    ];
