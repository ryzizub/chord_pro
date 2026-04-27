import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

RawLine _line(String text) => RawLine(number: 1, text: text);

void main() {
  group('parseDirectiveLine', () {
    test('parses bare directive', () {
      final d = parseDirectiveLine(_line('{new_song}'))!;
      expect(d.name, 'new_song');
      expect(d.value, isNull);
      expect(d.selector, isNull);
      expect(d.polarity, Polarity.none);
    });

    test('parses directive with colon value', () {
      final d = parseDirectiveLine(_line('{title: Hello World}'))!;
      expect(d.name, 'title');
      expect(d.value, 'Hello World');
    });

    test('parses directive with whitespace-separated value', () {
      final d = parseDirectiveLine(_line('{meta artist Bob Dylan}'))!;
      expect(d.name, 'meta');
      expect(d.value, 'artist Bob Dylan');
    });

    test('lowercases name', () {
      final d = parseDirectiveLine(_line('{Title: X}'))!;
      expect(d.name, 'title');
    });

    test('captures positive selector', () {
      final d = parseDirectiveLine(_line('{title-guitar: Fancy}'))!;
      expect(d.name, 'title');
      expect(d.selector, 'guitar');
      expect(d.polarity, Polarity.positive);
      expect(d.value, 'Fancy');
    });

    test('captures negative selector via legacy + form', () {
      final d = parseDirectiveLine(_line('{title+pdf: Plain}'))!;
      expect(d.selector, 'pdf');
      expect(d.polarity, Polarity.negative);
    });

    test('captures spec-form postfix ! negation', () {
      final d = parseDirectiveLine(_line('{title-guitar!: Plain}'))!;
      expect(d.selector, 'guitar');
      expect(d.polarity, Polarity.negative);
    });

    test('still accepts non-spec prefix !sel for backward compatibility', () {
      final d = parseDirectiveLine(_line('{title-!guitar: Plain}'))!;
      expect(d.selector, 'guitar');
      expect(d.polarity, Polarity.negative);
    });

    test('returns null for malformed line (no closing brace)', () {
      expect(parseDirectiveLine(_line('{title: oops')), isNull);
    });

    test('returns null when line has trailing content', () {
      expect(parseDirectiveLine(_line('{title: X} and more')), isNull);
    });

    test('returns null for empty name', () {
      expect(parseDirectiveLine(_line('{}')), isNull);
      expect(parseDirectiveLine(_line('{: value}')), isNull);
    });

    test('tolerates surrounding whitespace', () {
      final d = parseDirectiveLine(_line('   {capo: 3}   '))!;
      expect(d.name, 'capo');
      expect(d.value, '3');
    });

    test('records span covering the braces', () {
      final d = parseDirectiveLine(_line('  {key: G}'))!;
      expect(d.span.line, 1);
      expect(d.span.column, 3);
      expect(d.span.length, '{key: G}'.length);
    });
  });
}
