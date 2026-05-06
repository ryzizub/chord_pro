import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('{transpose} postfix qualifier (Transpose.pm:114)', () {
    test('plain integer -> none', () {
      final m = ChordPro.parseSong('{transpose: 3}').metadata;
      expect(m.transpose, 3);
      expect(m.transposeQualifier, TransposeQualifier.none);
    });

    test('s suffix -> sharps', () {
      final m = ChordPro.parseSong('{transpose: 3s}').metadata;
      expect(m.transpose, 3);
      expect(m.transposeQualifier, TransposeQualifier.sharps);
    });

    test('# alias -> sharps', () {
      final m = ChordPro.parseSong('{transpose: -2#}').metadata;
      expect(m.transpose, -2);
      expect(m.transposeQualifier, TransposeQualifier.sharps);
    });

    test('sharp glyph alias -> sharps', () {
      final m = ChordPro.parseSong('{transpose: 5♯}').metadata;
      expect(m.transpose, 5);
      expect(m.transposeQualifier, TransposeQualifier.sharps);
    });

    test('f suffix -> flats', () {
      final m = ChordPro.parseSong('{transpose: 3f}').metadata;
      expect(m.transposeQualifier, TransposeQualifier.flats);
    });

    test('b alias -> flats', () {
      final m = ChordPro.parseSong('{transpose: -2b}').metadata;
      expect(m.transposeQualifier, TransposeQualifier.flats);
    });

    test('flat glyph alias -> flats', () {
      final m = ChordPro.parseSong('{transpose: 5♭}').metadata;
      expect(m.transposeQualifier, TransposeQualifier.flats);
    });

    test('k suffix -> followKey (ChordPro 6.100)', () {
      final m = ChordPro.parseSong('{transpose: 5k}').metadata;
      expect(m.transpose, 5);
      expect(m.transposeQualifier, TransposeQualifier.followKey);
    });

    test('0k for key-following lock without shift', () {
      final m = ChordPro.parseSong('{transpose: 0k}').metadata;
      expect(m.transpose, 0);
      expect(m.transposeQualifier, TransposeQualifier.followKey);
    });

    test('garbage suffix is dropped, transpose stays null', () {
      final m = ChordPro.parseSong('{transpose: 3xy}').metadata;
      expect(m.transpose, isNull);
      expect(m.transposeQualifier, TransposeQualifier.none);
    });

    test('signed positive integer +3 accepted', () {
      final m = ChordPro.parseSong('{transpose: +3}').metadata;
      expect(m.transpose, 3);
    });
  });
}
