import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('ChordDefinition parsing', () {
    test('parses a full define directive', () {
      const source =
          '{define: G base-fret 1 frets 3 2 0 0 0 3 fingers 2 1 0 0 0 3}';
      final song = ChordPro.parseSong(source);
      expect(song.chordDefinitions, hasLength(1));
      final def = song.chordDefinitions.single;
      expect(def.name, 'G');
      expect(def.baseFret, 1);
      expect(def.frets, [3, 2, 0, 0, 0, 3]);
      expect(def.fingers, [2, 1, 0, 0, 0, 3]);
    });

    test('records muted strings as null', () {
      const source = '{chord: D frets x x 0 2 3 2}';
      final song = ChordPro.parseSong(source);
      expect(song.chordDefinitions.single.frets, [null, null, 0, 2, 3, 2]);
    });

    test('emits a diagnostic for an empty define', () {
      final result = ChordPro.parse('{define:}');
      expect(result.songs.single.chordDefinitions, isEmpty);
    });
  });

  group('Selector-aware metadata', () {
    test('skips selector-tagged titles by default', () {
      const source = '{title: Plain}\n{title-guitar: Fancy}';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.titles, ['Plain']);
    });
  });
}
