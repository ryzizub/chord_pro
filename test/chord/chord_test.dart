import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Chord.tryParse', () {
    test('parses a plain letter chord', () {
      final c = Chord.tryParse('C')!;
      expect(c.system, ChordSystem.letter);
      expect(c.root, 'C');
      expect(c.quality, isNull);
      expect(c.bass, isNull);
    });

    test('parses a minor chord with accidental', () {
      final c = Chord.tryParse('F#m')!;
      expect(c.root, 'F#');
      expect(c.quality, 'm');
    });

    test('parses slash chord with bass note', () {
      final c = Chord.tryParse('G/B')!;
      expect(c.root, 'G');
      expect(c.bass?.root, 'B');
    });

    test('captures extensions verbatim', () {
      final c = Chord.tryParse('Cmaj7')!;
      expect(c.root, 'C');
      expect(c.quality, 'maj');
      expect(c.extensions, ['7']);
    });

    test('parses Nashville numeric chord', () {
      final c = Chord.tryParse('4m')!;
      expect(c.system, ChordSystem.nashville);
      expect(c.root, '4');
      expect(c.quality, 'm');
    });

    test('parses Roman numeral chord', () {
      final c = Chord.tryParse('IV')!;
      expect(c.system, ChordSystem.roman);
      expect(c.root, 'IV');
    });

    test('returns null for empty input', () {
      expect(Chord.tryParse(''), isNull);
    });

    test('returns null for non-chord garbage', () {
      expect(Chord.tryParse('?@!'), isNull);
    });
  });
}
