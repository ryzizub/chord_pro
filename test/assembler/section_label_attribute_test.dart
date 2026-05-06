import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('section start label="..." attribute (Song.pm:1382)', () {
    test('verse with label= attribute', () {
      const src = '{start_of_verse: label="Verse 1"}\nLine\n{end_of_verse}';
      final song = ChordPro.parseSong(src);
      expect(song.sections.single.label, 'Verse 1');
    });

    test('verse with no-colon label= attribute', () {
      const src = '{start_of_verse label="Verse 1"}\nLine\n{end_of_verse}';
      expect(ChordPro.parseSong(src).sections.single.label, 'Verse 1');
    });

    test('legacy bare value still works', () {
      const src = '{start_of_verse: Verse 1}\nLine\n{end_of_verse}';
      expect(ChordPro.parseSong(src).sections.single.label, 'Verse 1');
    });

    test('chorus with label and extra attrs surfaces in attributes map', () {
      const src =
          '{start_of_chorus: label="Final" foo=bar}\nL\n{end_of_chorus}';
      final s = ChordPro.parseSong(src).sections.single;
      expect(s.label, 'Final');
      expect(s.attributes['foo'], 'bar');
    });

    test('all section kinds accept label= attr', () {
      for (final kind in [
        'verse',
        'chorus',
        'bridge',
        'tab',
        'grid',
        'abc',
        'ly',
        'svg',
        'textblock',
      ]) {
        final src = '{start_of_$kind: label="X"}\n{end_of_$kind}';
        expect(
          ChordPro.parseSong(src).sections.single.label,
          'X',
          reason: 'kind=$kind',
        );
      }
    });
  });
}
