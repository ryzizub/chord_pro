import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('start_of_textblock attributes (6.050+)', () {
    test('full textblock-specific attribute set', () {
      const src = '{start_of_textblock width=200 height=100 padding=5 '
          'flush=center vflush=top textstyle=verse textsize=12 '
          'textspacing=1.2 textcolor="#333" background="#fff" '
          'omit=0}\nbody\n{end_of_textblock}';
      final t = ChordPro.parseSong(src).sections.single.textblockAttributes!;
      expect(t.width, '200');
      expect(t.height, '100');
      expect(t.padding, '5');
      expect(t.flush, 'center');
      expect(t.vflush, 'top');
      expect(t.textstyle, 'verse');
      expect(t.textsize, '12');
      expect(t.textspacing, '1.2');
      expect(t.textcolor, '#333');
      expect(t.background, '#fff');
      expect(t.omit, '0');
    });

    test('image-inherited attrs surface as typed fields', () {
      const src = '{start_of_textblock label="Note" align=right '
          'anchor=column x=5 y=10 border=2 href="https://x" '
          'title="hover"}\nbody\n{end_of_textblock}';
      final s = ChordPro.parseSong(src).sections.single;
      expect(s.label, 'Note');
      final t = s.textblockAttributes!;
      expect(t.align, 'right');
      expect(t.anchor, 'column');
      expect(t.x, '5');
      expect(t.y, '10');
      expect(t.border, '2');
      expect(t.href, 'https://x');
      expect(t.title, 'hover');
    });

    test('color/bgcolor aliases mapped to textcolor/background', () {
      const src = '{start_of_textblock color="#ff0" bgcolor="#000"}'
          '\nbody\n{end_of_textblock}';
      final t = ChordPro.parseSong(src).sections.single.textblockAttributes!;
      expect(t.textcolor, '#ff0');
      expect(t.background, '#000');
    });

    test('textblockAttributes only set when kind is textblock', () {
      const src = '{start_of_verse}\nLine\n{end_of_verse}';
      expect(
        ChordPro.parseSong(src).sections.single.textblockAttributes,
        isNull,
      );
    });
  });
}
