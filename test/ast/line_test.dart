import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Line kind predicates', () {
    test('a structured lyric line', () {
      final line = ChordPro.parseSong('[C]hi').sections.first.lines.first;
      expect(line.kind, LineKind.structured);
      expect(line.isVerbatim, isFalse);
      expect(line.isComment, isFalse);
      expect(line.isImage, isFalse);
      expect(line.isLayoutBreak, isFalse);
    });

    test('a verbatim tab line', () {
      final line = ChordPro.parseSong('{start_of_tab}\ne|--0--|\n{end_of_tab}')
          .sections
          .first
          .lines
          .first;
      expect(line.isVerbatim, isTrue);
      expect(line.verbatim, 'e|--0--|');
      expect(line.tokens, isEmpty);
    });

    test('a comment line', () {
      final line =
          ChordPro.parseSong('{comment: hi}').sections.first.lines.first;
      expect(line.isComment, isTrue);
      expect(line.comment, 'hi');
      expect(line.commentStyle, CommentStyle.plain);
    });

    test('an image line', () {
      final line = ChordPro.parseSong('{image: src="cover.png"}')
          .sections
          .first
          .lines
          .first;
      expect(line.isImage, isTrue);
      expect(line.isLayoutBreak, isFalse);
      expect(line.image?.src, 'cover.png');
    });

    test('a layout-break line', () {
      for (final entry in const {
        '{new_page}': LayoutBreak.newPage,
        '{np}': LayoutBreak.newPage,
        '{new_physical_page}': LayoutBreak.newPhysicalPage,
        '{npp}': LayoutBreak.newPhysicalPage,
        '{column_break}': LayoutBreak.columnBreak,
        '{colb}': LayoutBreak.columnBreak,
      }.entries) {
        final line = ChordPro.parseSong(entry.key).sections.first.lines.first;
        expect(line.isLayoutBreak, isTrue, reason: entry.key);
        expect(line.isImage, isFalse, reason: entry.key);
        expect(line.layoutBreak, entry.value, reason: entry.key);
      }
    });
  });
}
