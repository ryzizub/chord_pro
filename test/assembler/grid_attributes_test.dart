import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('start_of_grid attributes (Song.pm:1479-1525)', () {
    test('legacy bare cells {sog: 4x4}', () {
      const src = '{sog: 4x4}\n| C . . . | G . . . |\n{eog}';
      final g = ChordPro.parseSong(src).sections.single.gridAttributes!;
      expect(g.measures, 4);
      expect(g.beats, 4);
      expect(g.leftMargin, isNull);
      expect(g.rightMargin, isNull);
    });

    test('shape with margins {sog: 1+4x4+1}', () {
      const src = '{sog: 1+4x4+1}\n.|C.. .|.\n{eog}';
      final g = ChordPro.parseSong(src).sections.single.gridAttributes!;
      expect(g.leftMargin, 1);
      expect(g.measures, 4);
      expect(g.beats, 4);
      expect(g.rightMargin, 1);
    });

    test('explicit shape= and label= {sog: shape="4x4" label="Intro"}', () {
      const src = '{sog: shape="4x4" label="Intro"}\n|C . . .|\n{eog}';
      final s = ChordPro.parseSong(src).sections.single;
      expect(s.label, 'Intro');
      expect(s.gridAttributes?.measures, 4);
      expect(s.gridAttributes?.beats, 4);
    });

    test('cc default is "grid"', () {
      const src = '{sog: 4x4}\n|C . . .|\n{eog}';
      expect(
        ChordPro.parseSong(src).sections.single.gridAttributes?.cc,
        'grid',
      );
    });

    test('cc can be overridden', () {
      const src = '{sog: shape="4x4" cc="intro"}\n|C . . .|\n{eog}';
      expect(
        ChordPro.parseSong(src).sections.single.gridAttributes?.cc,
        'intro',
      );
    });

    test('gridAttributes only set when kind is grid', () {
      const src = '{start_of_verse}\nLine\n{end_of_verse}';
      expect(ChordPro.parseSong(src).sections.single.gridAttributes, isNull);
    });
  });
}
