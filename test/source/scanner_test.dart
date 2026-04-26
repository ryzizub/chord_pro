import 'package:chord_pro/src/source/scanner.dart';
import 'package:test/test.dart';

void main() {
  group('scan', () {
    test('returns empty list for empty input', () {
      expect(scan(''), isEmpty);
    });

    test('splits on LF, CRLF, and lone CR', () {
      final lines = scan('a\nb\r\nc\rd');
      expect(lines.map((l) => l.text).toList(), ['a', 'b', 'c', 'd']);
      expect(lines.map((l) => l.number).toList(), [1, 2, 3, 4]);
    });

    test('does not emit trailing blank after terminal newline', () {
      final lines = scan('only\n');
      expect(lines, hasLength(1));
      expect(lines.single.text, 'only');
    });

    test('preserves blank lines in the middle', () {
      final lines = scan('a\n\nb');
      expect(lines.map((l) => l.text).toList(), ['a', '', 'b']);
      expect(lines[1].isBlank, isTrue);
    });

    test('detects file-comment lines', () {
      final lines = scan('# top\n  # indented\nplain\n#');
      expect(lines.map((l) => l.isFileComment).toList(), [
        true,
        true,
        false,
        true,
      ]);
    });
  });
}
