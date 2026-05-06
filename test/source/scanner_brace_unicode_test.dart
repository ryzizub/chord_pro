import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('scanner unicode escapes', () {
    test('brace form lowercase', () {
      final song = ChordPro.parseSong(r'{title: Caf\u{e9}}');
      expect(song.metadata.titles.single, 'Café');
    });

    test('brace form astral codepoint', () {
      final song = ChordPro.parseSong(r'{title: \u{1F3B8} on tour}');
      expect(song.metadata.titles.single, '\u{1F3B8} on tour');
    });

    test('brace form uppercase', () {
      final song = ChordPro.parseSong(r'{title: caf\u{E9}}');
      expect(song.metadata.titles.single, 'café');
    });

    test('legacy 4-digit form still resolves', () {
      final song = ChordPro.parseSong(r'{title: caf\u00e9}');
      expect(song.metadata.titles.single, 'café');
    });

    test('surrogate pair recombines', () {
      final song = ChordPro.parseSong(r'{title: \uD83C\uDFB8 on tour}');
      expect(song.metadata.titles.single, '\u{1F3B8} on tour');
    });
  });
}
