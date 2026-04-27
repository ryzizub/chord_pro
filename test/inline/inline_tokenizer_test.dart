import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

RawLine _line(String text) => RawLine(number: 1, text: text);

void main() {
  group('tokenizeInline', () {
    test('plain text → single TextToken', () {
      final tokens = tokenizeInline(_line('Mama, take this badge'));
      expect(tokens, hasLength(1));
      expect(tokens.single, isA<TextToken>());
      expect((tokens.single as TextToken).text, 'Mama, take this badge');
    });

    test('inline chord splits text', () {
      final tokens = tokenizeInline(_line('[G]Mama, take this [D]badge'));
      expect(tokens.map((t) => t.runtimeType.toString()).toList(), [
        'ChordToken',
        'TextToken',
        'ChordToken',
        'TextToken',
      ]);
      final first = tokens[0] as ChordToken;
      expect(first.raw, 'G');
      expect(first.chord?.root, 'G');
      expect((tokens[1] as TextToken).text, 'Mama, take this ');
      expect((tokens[3] as TextToken).text, 'badge');
    });

    test('annotation token', () {
      final tokens = tokenizeInline(_line('[*capo on 3]'));
      expect(tokens, hasLength(1));
      expect(tokens.single, isA<AnnotationToken>());
      expect((tokens.single as AnnotationToken).text, 'capo on 3');
    });

    test('inline directive token', () {
      final tokens = tokenizeInline(_line('before {comment: hey} after'));
      expect(tokens, hasLength(3));
      expect(tokens[1], isA<InlineDirectiveToken>());
      final directive = (tokens[1] as InlineDirectiveToken).directive;
      expect(directive.name, 'comment');
      expect(directive.value, 'hey');
    });

    test('unterminated bracket is treated as literal', () {
      final tokens = tokenizeInline(_line('unclosed [G'));
      expect(tokens.every((t) => t is TextToken), isTrue);
      final joined = tokens.cast<TextToken>().map((t) => t.text).join();
      expect(joined, 'unclosed [G');
    });

    test('backslash escapes brackets and braces', () {
      final tokens = tokenizeInline(_line(r'literal \[G\] and \{x\}'));
      expect(tokens, hasLength(1));
      expect((tokens.single as TextToken).text, 'literal [G] and {x}');
    });

    test('unparseable chord keeps raw, chord is null', () {
      final tokens = tokenizeInline(_line('[???]'));
      final chord = tokens.single as ChordToken;
      expect(chord.raw, '???');
      expect(chord.chord, isNull);
    });
  });
}
