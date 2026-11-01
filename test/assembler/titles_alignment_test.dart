import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('{titles} alignment (Song.pm:2204)', () {
    test('{titles: center}', () {
      expect(
        ChordPro.parseSong('{titles: center}').titlesAlignment,
        TitlesAlignment.center,
      );
    });

    test('{titles: centre} aliases to center', () {
      expect(
        ChordPro.parseSong('{titles: centre}').titlesAlignment,
        TitlesAlignment.center,
      );
    });

    test('{titles: LEFT} case-insensitive', () {
      expect(
        ChordPro.parseSong('{titles: LEFT}').titlesAlignment,
        TitlesAlignment.left,
      );
    });

    test('{titles: right}', () {
      expect(
        ChordPro.parseSong('{titles: right}').titlesAlignment,
        TitlesAlignment.right,
      );
    });

    test('{titles: bogus} -> null', () {
      expect(
        ChordPro.parseSong('{titles: bogus}').titlesAlignment,
        isNull,
      );
    });

    test('no {titles} directive -> null', () {
      expect(ChordPro.parseSong('{title: A}').titlesAlignment, isNull);
    });

    test('{titles-x: center} without selector x -> null', () {
      final song = ChordPro.parseSong('{titles-x: center}');
      expect(song.titlesAlignment, isNull);
      expect(song.directives.single.selector, 'x');
    });

    test('{titles-x: center} with selector x -> center', () {
      expect(
        ChordPro.parseSong('{titles-x: center}', selectors: {'x'})
            .titlesAlignment,
        TitlesAlignment.center,
      );
    });
  });
}
