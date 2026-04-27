import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('SourceSpan', () {
    test('toString renders line:column+length', () {
      const span = SourceSpan(line: 12, column: 4, length: 7);
      expect(span.toString(), '12:4+7');
    });
  });
}
