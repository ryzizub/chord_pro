import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('{chorus} recall (Song.pm:1755 - all 4 forms)', () {
    test('bare {chorus}', () {
      final s = ChordPro.parseSong('{chorus}').sections.single;
      expect(s.isChorusRecall, isTrue);
      expect(s.label, isNull);
    });

    test('{chorus: Final} legacy bare value', () {
      final s = ChordPro.parseSong('{chorus: Final}').sections.single;
      expect(s.isChorusRecall, isTrue);
      expect(s.label, 'Final');
    });

    test('{chorus: label="Final"} modern (6.060)', () {
      final s = ChordPro.parseSong('{chorus: label="Final"}').sections.single;
      expect(s.isChorusRecall, isTrue);
      expect(s.label, 'Final');
    });

    test('{chorus label="Final"} modern no-colon', () {
      final s = ChordPro.parseSong('{chorus label="Final"}').sections.single;
      expect(s.isChorusRecall, isTrue);
      expect(s.label, 'Final');
    });
  });
}
