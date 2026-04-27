import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Diagnostic', () {
    test('toString includes severity, span and message', () {
      const diagnostic = Diagnostic(
        severity: DiagnosticSeverity.warning,
        message: 'unterminated chorus',
        span: SourceSpan(line: 4, column: 1, length: 12),
      );
      expect(diagnostic.toString(), '[warning] 4:1+12: unterminated chorus');
    });
  });
}
