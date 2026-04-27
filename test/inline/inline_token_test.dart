import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  const span = SourceSpan(line: 1, column: 1, length: 1);

  group('InlineToken.toString', () {
    test('TextToken renders text', () {
      const token = TextToken(text: 'hello', span: span);
      expect(token.toString(), 'TextToken(hello)');
    });

    test('ChordToken renders raw', () {
      const token = ChordToken(raw: 'G', chord: null, span: span);
      expect(token.toString(), 'ChordToken(G)');
    });

    test('AnnotationToken renders annotation text', () {
      const token = AnnotationToken(text: 'capo on 3', span: span);
      expect(token.toString(), 'AnnotationToken(capo on 3)');
    });

    test('InlineDirectiveToken renders the directive', () {
      const directive = Directive(name: 'comment', span: span, value: 'hey');
      const token = InlineDirectiveToken(directive: directive, span: span);
      expect(token.toString(), 'InlineDirectiveToken({comment: hey})');
    });
  });
}
