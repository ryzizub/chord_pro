import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Diagnostic', () {
    test('toString includes severity, span and message', () {
      const diagnostic = Diagnostic(
        severity: DiagnosticSeverity.warning,
        code: DiagnosticCode.unterminatedSection,
        message: 'unterminated chorus',
        span: SourceSpan(line: 4, column: 1, length: 12),
      );
      expect(diagnostic.toString(), '[warning] 4:1+12: unterminated chorus');
    });

    test('carries a stable code independent of the message', () {
      const a = Diagnostic(
        severity: DiagnosticSeverity.warning,
        code: DiagnosticCode.strayEnd,
        message: 'one wording',
        span: SourceSpan(line: 1, column: 1, length: 1),
      );
      const b = Diagnostic(
        severity: DiagnosticSeverity.warning,
        code: DiagnosticCode.strayEnd,
        message: 'another wording',
        span: SourceSpan(line: 1, column: 1, length: 1),
      );
      expect(a.code, b.code);
      expect(a, isNot(b));
    });
  });
}
