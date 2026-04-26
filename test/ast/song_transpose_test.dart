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

    test('zero-step transposition is identity', () {
      final song = ChordPro.parseSong('{key: G}\n[G]hi');
      expect(identical(song.transposed(0), song), isTrue);
    });
  });
}
