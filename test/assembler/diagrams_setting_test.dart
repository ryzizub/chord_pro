import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('{diagrams} setting (Song.pm:2235-2247)', () {
    test('{diagrams: on} -> enabled, no position', () {
      final d = ChordPro.parseSong('{diagrams: on}').diagrams;
      expect(d?.enabled, isTrue);
      expect(d?.position, isNull);
    });

    test('{diagrams: off} -> disabled', () {
      expect(
        ChordPro.parseSong('{diagrams: off}').diagrams?.enabled,
        isFalse,
      );
    });

    test('{diagrams: top} -> enabled with position', () {
      final d = ChordPro.parseSong('{diagrams: top}').diagrams;
      expect(d?.enabled, isTrue);
      expect(d?.position, DiagramsPosition.top);
    });

    test('{diagrams: bottom}', () {
      final d = ChordPro.parseSong('{diagrams: bottom}').diagrams;
      expect(d?.position, DiagramsPosition.bottom);
    });

    test('{diagrams: right}', () {
      final d = ChordPro.parseSong('{diagrams: right}').diagrams;
      expect(d?.position, DiagramsPosition.right);
    });

    test('{diagrams: below}', () {
      final d = ChordPro.parseSong('{diagrams: below}').diagrams;
      expect(d?.position, DiagramsPosition.below);
    });

    test('{g: bottom} alias for {diagrams: bottom}', () {
      final d = ChordPro.parseSong('{g: bottom}').diagrams;
      expect(d?.position, DiagramsPosition.bottom);
    });

    test('bare {diagrams} -> enabled', () {
      expect(
        ChordPro.parseSong('{diagrams}').diagrams?.enabled,
        isTrue,
      );
    });

    test('no {diagrams} directive -> null', () {
      expect(ChordPro.parseSong('{title: A}').diagrams, isNull);
    });
  });

  // ChordPro abbrevs: ng => no_grid; dir_grid enables, dir_no_grid disables.
  // Spec ref: https://www.chordpro.org/chordpro/directives-diagrams/
  group('{grid} / {no_grid} / {ng} (Song.pm abbrevs + dir_grid/dir_no_grid)', () {
    test('{grid} enables diagram display', () {
      final d = ChordPro.parseSong('{grid}').diagrams;
      expect(d?.enabled, isTrue);
      expect(d?.position, isNull);
    });

    test('{no_grid} disables diagram display', () {
      expect(ChordPro.parseSong('{no_grid}').diagrams?.enabled, isFalse);
    });

    test('{ng} is the spec alias for {no_grid}', () {
      expect(ChordPro.parseSong('{ng}').diagrams?.enabled, isFalse);
    });

    test('{grid} then {no_grid} — last writer wins', () {
      expect(
        ChordPro.parseSong('{grid}\n{no_grid}').diagrams?.enabled,
        isFalse,
      );
    });
  });
}
