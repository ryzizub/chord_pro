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
      expect(c.extension, '7');
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

    test('accepts the German H letter root', () {
      final c = Chord.tryParse('Hm')!;
      expect(c.system, ChordSystem.letter);
      expect(c.root, 'H');
      expect(c.quality, 'm');
    });

    test('accepts unicode flat and sharp accidentals', () {
      final flat = Chord.tryParse('B♭maj7')!;
      expect(flat.root, 'B♭');
      expect(flat.quality, 'maj');
      final sharp = Chord.tryParse('F♯m')!;
      expect(sharp.root, 'F♯');
      expect(sharp.quality, 'm');
    });

    test('accepts mi/min/- as minor qualities', () {
      expect(Chord.tryParse('Cmi')!.quality, 'mi');
      expect(Chord.tryParse('C-')!.quality, '-');
    });

    test('parses half-diminished and diminished glyph qualities', () {
      expect(Chord.tryParse('Bø7')!.quality, 'ø');
      expect(Chord.tryParse('C°')!.quality, '°');
    });

    test('parses spec chord qualifiers `^`, `h`, `0`', () {
      // `^` is the spec-defined alternate for `maj`.
      expect(Chord.tryParse('C^7')!.quality, '^');
      expect(Chord.tryParse('C^7')!.extension, '7');
      // `h` is half-diminished.
      expect(Chord.tryParse('Bh7')!.quality, 'h');
      // `0` (literal zero) is diminished.
      expect(Chord.tryParse('C0')!.quality, '0');
    });

    test('parses `+` as augmented quality (spec alternate for `aug`)', () {
      // `+` is the spec-defined alternate for `aug`.
      final c = Chord.tryParse('C+')!;
      expect(c.root, 'C');
      expect(c.quality, '+');
      expect(c.extension, isNull);
      // With extension.
      final c7 = Chord.tryParse('C+7')!;
      expect(c7.root, 'C');
      expect(c7.quality, '+');
      expect(c7.extension, '7');
    });

    test('parses NC as a no-chord marker', () {
      final c = Chord.tryParse('NC')!;
      expect(c.root, 'NC');
      expect(c.raw, 'NC');
    });
  });

  group('Chord notation systems', () {
    test('a flat Nashville root is Nashville, not a letter chord', () {
      // `b7` is the flat seventh degree. The leading `b` also starts a
      // notes-mode lowercase root, so the system has to come from the
      // branch that matched rather than from the root text.
      for (final raw in ['b1', 'b3', 'b7']) {
        final c = Chord.tryParse(raw);
        expect(c, isNotNull, reason: raw);
        expect(c!.system, ChordSystem.nashville, reason: raw);
        expect(c.root, raw, reason: raw);
      }
    });

    test('a sharp Nashville root is Nashville', () {
      final c = Chord.tryParse('#4')!;
      expect(c.system, ChordSystem.nashville);
      expect(c.root, '#4');
    });

    test('notes mode makes a lowercase root a letter chord', () {
      final c = Chord.tryParse('b7', notesMode: true)!;
      expect(c.system, ChordSystem.letter);
      expect(c.root, 'b');
      expect(c.extension, '7');
      final flat = Chord.tryParse('bb', notesMode: true)!;
      expect(flat.system, ChordSystem.letter);
      expect(flat.root, 'bb');
    });

    test('a lowercase root is not a chord outside notes mode', () {
      expect(Chord.tryParse('c'), isNull);
      expect(Chord.tryParse('bb'), isNull);
    });

    test('Nashville and Roman chords pass through transposition', () {
      expect(Chord.tryParse('b7')!.transpose(2).raw, 'b7');
      expect(Chord.tryParse('IV')!.transpose(2).raw, 'IV');
    });
  });

  group('transposeRoot', () {
    test('accepts Unicode accidentals on input', () {
      expect(transposeRoot('B♭', 2), 'C');
      expect(transposeRoot('F♯', 1), 'G');
    });

    test('accepts German H as B natural', () {
      expect(transposeRoot('H', 1), 'C');
    });

    test('spells with flats on request', () {
      expect(
        transposeRoot('C', 1, accidentals: AccidentalPreference.flats),
        'Db',
      );
    });

    test('wraps negative shifts', () {
      expect(transposeRoot('C', -1), 'B');
      expect(transposeRoot('C', -13), 'B');
    });

    test('returns null for an unrecognised root', () {
      expect(transposeRoot('H#', 1), isNull);
      expect(transposeRoot('zz', 1), isNull);
    });

    test('forceCommonKeys substitutes the awkward sharp keys', () {
      expect(transposeRoot('C', 1, forceCommonKeys: true), 'Db');
      expect(transposeRoot('C', 3, forceCommonKeys: true), 'Eb');
      expect(transposeRoot('C', 8, forceCommonKeys: true), 'Ab');
      expect(transposeRoot('C', 10, forceCommonKeys: true), 'Bb');
      // A root that is already easy is left alone.
      expect(transposeRoot('C', 2, forceCommonKeys: true), 'D');
    });
  });

  group('Chord.transpose', () {
    test('shifts a sharp letter chord up by semitones', () {
      final c = Chord.tryParse('Cmaj7')!.transpose(2);
      expect(c.root, 'D');
      expect(c.raw, 'Dmaj7');
    });

    test('wraps around the octave', () {
      final c = Chord.tryParse('B')!.transpose(1);
      expect(c.root, 'C');
    });

    test('honours flat preference when requested', () {
      final c = Chord.tryParse('C')!
          .transpose(1, accidentals: AccidentalPreference.flats);
      expect(c.root, 'Db');
    });

    test('transposes the bass note too', () {
      final c = Chord.tryParse('G/B')!.transpose(2);
      expect(c.root, 'A');
      expect(c.bass?.root, 'C#');
      expect(c.raw, 'A/C#');
    });

    test('leaves Nashville chords unchanged', () {
      final c = Chord.tryParse('4m')!.transpose(3);
      expect(c.raw, '4m');
    });

    test('leaves Roman chords unchanged', () {
      final c = Chord.tryParse('IV')!.transpose(3);
      expect(c.raw, 'IV');
    });

    test('treats German H as B for transposition', () {
      final c = Chord.tryParse('H')!.transpose(1);
      expect(c.root, 'C');
    });

    test('accepts unicode-accidental roots when transposing', () {
      final c = Chord.tryParse('F♯m')!.transpose(2);
      expect(c.root, 'G#');
    });
  });
}
