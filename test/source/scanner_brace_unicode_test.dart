import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('scanner unicode escapes', () {
    test('brace form lowercase', () {
      final song = ChordPro.parseSong(r'{title: Caf\u{e9}}');
      expect(song.metadata.titles.single, 'Café');
    });

    test('brace form with a single hex digit', () {
      // The brace form takes one or more hex digits, so `\u{7}` is a
      // complete escape even though it is only five characters — short
      // enough that a minimum-length guard would skip it and leave the
      // inline tokenizer to eat the backslash.
      final song = ChordPro.parseSong(r'\u{7}');
      final text = song.sections.first.lines.first.tokens
          .whereType<TextToken>()
          .map((t) => t.text)
          .join();
      expect(text, '\u0007');
    });

    test('a short escape resolves mid-line too', () {
      final song = ChordPro.parseSong(r'A\u{9}B');
      final text = song.sections.first.lines.first.tokens
          .whereType<TextToken>()
          .map((t) => t.text)
          .join();
      expect(text, 'A\tB');
    });

    test('a line with no backslash is passed through untouched', () {
      final song = ChordPro.parseSong('plain lyric line');
      final text = song.sections.first.lines.first.tokens
          .whereType<TextToken>()
          .map((t) => t.text)
          .join();
      expect(text, 'plain lyric line');
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
