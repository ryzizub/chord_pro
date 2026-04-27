import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  const span = SourceSpan(line: 1, column: 1, length: 1);

  group('Directive', () {
    test('toString renders bare directive', () {
      const directive = Directive(name: 'new_song', span: span);
      expect(directive.toString(), '{new_song}');
    });

    test('toString renders directive with value', () {
      const directive = Directive(name: 'title', span: span, value: 'Demo');
      expect(directive.toString(), '{title: Demo}');
    });

    test('toString renders positive selector', () {
      const directive = Directive(
        name: 'title',
        span: span,
        selector: 'guitar',
        polarity: Polarity.positive,
        value: 'Demo',
      );
      expect(directive.toString(), '{title-guitar: Demo}');
    });

    test('toString renders negative selector in spec form', () {
      const directive = Directive(
        name: 'title',
        span: span,
        selector: 'piano',
        polarity: Polarity.negative,
        value: 'Demo',
      );
      expect(directive.toString(), '{title-!piano: Demo}');
    });

    test('isCustomExtension recognises x_* namespace', () {
      const custom = Directive(name: 'x_my_tool', span: span);
      const standard = Directive(name: 'title', span: span);
      expect(custom.isCustomExtension, isTrue);
      expect(standard.isCustomExtension, isFalse);
    });
  });
}
