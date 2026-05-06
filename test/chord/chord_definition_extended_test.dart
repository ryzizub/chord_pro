import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('ChordDefinition extended attributes (Song.pm 2483-2616)', () {
    test('display attribute (5.989)', () {
      final song = ChordPro.parseSong('{define: G display G/B}');
      final def = song.chordDefinitions.single;
      expect(def.name, 'G');
      expect(def.display, 'G/B');
    });

    test('format attribute (verbatim quoted string)', () {
      // Format strings with %{...} substitutions are documented as
      // passed through verbatim; the test value here avoids a literal
      // `}` because the directive parser closes on the first
      // unescaped `}` — a separate concern, not chord-definition.
      final song = ChordPro.parseSong(
        '{define: G format "X<sup>maj7</sup>"}',
      );
      expect(
        song.chordDefinitions.single.format,
        'X<sup>maj7</sup>',
      );
    });

    test('keys attribute (0.979)', () {
      final song = ChordPro.parseSong('{define: C keys 0 4 7}');
      expect(song.chordDefinitions.single.keys, [0, 4, 7]);
    });

    test('copy attribute', () {
      final song = ChordPro.parseSong('{define: Gnew copy G}');
      expect(song.chordDefinitions.single.copy, 'G');
    });

    test('copyall attribute', () {
      final song = ChordPro.parseSong('{define: Gnew copyall G}');
      expect(song.chordDefinitions.single.copyall, 'G');
    });

    test('diagram on/off/colour (6.010)', () {
      final song = ChordPro.parseSong('{define: G diagram off}');
      expect(song.chordDefinitions.single.diagram, 'off');
    });

    test('fret value -1 muted (6.060)', () {
      final song = ChordPro.parseSong(
        '{define: Em base-fret 1 frets 0 2 2 0 0 -1}',
      );
      expect(
        song.chordDefinitions.single.frets,
        [0, 2, 2, 0, 0, null],
      );
    });

    test('fret value N muted', () {
      final song = ChordPro.parseSong(
        '{define: Em base-fret 1 frets 0 2 2 0 0 N}',
      );
      expect(song.chordDefinitions.single.frets.last, isNull);
    });

    test('finger letter A is preserved as String', () {
      final song = ChordPro.parseSong(
        '{define: G base-fret 1 frets 3 2 0 0 0 3 fingers 3 2 - - - A}',
      );
      expect(
        song.chordDefinitions.single.fingers,
        [3, 2, null, null, null, 'A'],
      );
    });

    test('bracketed name is transposable, attrs ignored', () {
      final song = ChordPro.parseSong(
        '{define: [Cmaj7] base-fret 8 frets 8 10 9 9 8 8}',
      );
      final def = song.chordDefinitions.single;
      expect(def.name, 'Cmaj7');
      expect(def.isTransposable, isTrue);
      // Attributes are discarded for transposable definitions.
      expect(def.frets, isEmpty);
      expect(def.fingers, isEmpty);
    });

    test('bare define (just name) registers the chord (5.989)', () {
      final song = ChordPro.parseSong('{define: NC}');
      expect(song.chordDefinitions.single.name, 'NC');
      expect(song.chordDefinitions.single.frets, isEmpty);
    });
  });
}
