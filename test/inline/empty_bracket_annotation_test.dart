import 'package:chord_pro/src/inline/inline_token.dart';
import 'package:chord_pro/src/inline/inline_tokenizer.dart';
import 'package:chord_pro/src/source/raw_line.dart';
import 'package:test/test.dart';

void main() {
  RawLine line(String s) => RawLine(number: 1, text: s);

  group('emergency bracket recovery (ChordPro 6.020 + 6.080)', () {
    test('whitespace-only bracket [ ] becomes annotation', () {
      final tokens = tokenizeInline(line('Hello [ ] world'));
      final annotation = tokens.whereType<AnnotationToken>().single;
      expect(annotation.text, ' ');
    });

    test('pipe-only bracket [|] becomes annotation', () {
      final tokens = tokenizeInline(line('Hello [|] world'));
      final annotation = tokens.whereType<AnnotationToken>().single;
      expect(annotation.text, '|');
    });

    test('empty bracket [] emits no token (zero-width placeholder)', () {
      final tokens = tokenizeInline(line('Hello [] world'));
      expect(tokens.whereType<ChordToken>(), isEmpty);
      expect(tokens.whereType<AnnotationToken>(), isEmpty);
      expect(
        tokens.whereType<TextToken>().map((t) => t.text).join(),
        'Hello  world',
      );
    });

    test('asterisk-prefix annotation [*foo] still works', () {
      final tokens = tokenizeInline(line('[*muted]C'));
      final annotation = tokens.whereType<AnnotationToken>().single;
      expect(annotation.text, 'muted');
    });

    test('multiple-space bracket [   ] becomes annotation', () {
      final tokens = tokenizeInline(line('Hello [   ] world'));
      final annotation = tokens.whereType<AnnotationToken>().single;
      expect(annotation.text, '   ');
    });
  });
}
