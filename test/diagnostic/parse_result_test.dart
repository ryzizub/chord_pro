import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('ParseResult', () {
    test('equal results share a hash code', () {
      final a = ChordPro.parse('{title: x}\n{end_of_verse}');
      final b = ChordPro.parse('{title: x}\n{end_of_verse}');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a.diagnostics.map((d) => (code: d.code, line: d.span.line)),
        [(code: DiagnosticCode.strayEnd, line: 2)],
      );
    });
  });
}
