import 'package:chord_pro/chord_pro.dart';
import 'package:chord_pro/src/directive/image_directive.dart';
import 'package:chord_pro/src/source/source_span.dart';
import 'package:test/test.dart';

void main() {
  const span = SourceSpan(line: 1, column: 1, length: 0);

  group('parseImageDirective', () {
    test('parses src and scale', () {
      final image = parseImageDirective(
        'src="cover.png" scale="50%"',
        span: span,
      )!;
      expect(image.src, 'cover.png');
      expect(image.scale, '50%');
      expect(image.attributes, {'src': 'cover.png', 'scale': '50%'});
    });

    test('accepts unquoted values', () {
      final image = parseImageDirective(
        'src=cover.png width=200 align=center',
        span: span,
      )!;
      expect(image.src, 'cover.png');
      expect(image.width, '200');
      expect(image.align, 'center');
    });

    test('honours single quotes and escapes', () {
      final image = parseImageDirective(
        r"src='a b.png' title='it\'s nice'",
        span: span,
      )!;
      expect(image.src, 'a b.png');
      expect(image.title, "it's nice");
    });

    test('keeps unknown attributes verbatim', () {
      final image = parseImageDirective('src=x.png frob=42', span: span)!;
      expect(image.attributes['frob'], '42');
    });

    test('returns null for an empty body', () {
      expect(parseImageDirective('', span: span), isNull);
    });
  });

  group('Assembler image lines', () {
    test('emits image lines into sections', () {
      const source = '''
{start_of_verse}
[G]hello
{image: src="cover.png" scale=50%}
[D]world
{end_of_verse}
''';
      final song = ChordPro.parseSong(source);
      final lines = song.sections.single.lines;
      expect(lines.map((l) => l.kind).toList(), [
        LineKind.structured,
        LineKind.image,
        LineKind.structured,
      ]);
      expect(lines[1].image?.src, 'cover.png');
      expect(lines[1].image?.scale, '50%');
    });

    test('warns on empty {image}', () {
      final result = ChordPro.parse('{image:}');
      expect(result.diagnostics, hasLength(1));
      expect(result.songs.single.sections, isEmpty);
    });
  });
}
