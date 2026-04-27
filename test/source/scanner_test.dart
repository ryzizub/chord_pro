import 'package:chord_pro/chord_pro.dart';
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

    test(r'concatenates lines that end in `\` (ChordPro 6.01)', () {
      final lines = scan('one\\\n   two\nthree');
      expect(lines.map((l) => l.text).toList(), ['onetwo', 'three']);
      expect(lines.first.number, 1);
    });

    test(r'continuation chains across multiple `\`-terminated lines', () {
      final lines = scan('a\\\nb\\\n\tc\nd');
      expect(lines.map((l) => l.text).toList(), ['abc', 'd']);
    });

    test(r'leaves an even-count trailing `\` alone (escaped backslash)', () {
      final lines = scan(r'foo\\' '\nbar');
      expect(lines.map((l) => l.text).toList(), [r'foo\\', 'bar']);
    });

    test(r'resolves `\uXXXX` escapes (ChordPro 6.01)', () {
      // Source contains the literal six-char sequences
      // backslash-u-0-0-e-9 and backslash-u-2-6-6-f. Built via
      // codepoints to avoid the editor collapsing them.
      final source = String.fromCharCodes(<int>[
        0x43, 0x61, 0x66, // C a f
        0x5C, 0x75, 0x30, 0x30, 0x65, 0x39, // \u00e9
        0x20,
        0x5C, 0x75, 0x32, 0x36, 0x36, 0x66, // \u266f
      ]);
      final lines = scan(source);
      expect(lines.single.text, 'Café ♯');
    });

    test('leaves malformed unicode escapes alone', () {
      final lines = scan(r'oops \uZZZZ');
      expect(lines.single.text, r'oops \uZZZZ');
    });
  });
}
