import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  const span = SourceSpan(line: 1, column: 1, length: 0);

  group('ImageDirective typed accessors (added 6.010-6.080)', () {
    test('href (6.060)', () {
      final i = parseImageDirective(
        'src=x.png href="https://example.com"',
        span: span,
      )!;
      expect(i.href, 'https://example.com');
    });

    test('x and y (6.040)', () {
      final i = parseImageDirective(
        'src=x.png x=10 y=20',
        span: span,
      )!;
      expect(i.x, '10');
      expect(i.y, '20');
    });

    test('spread', () {
      final i = parseImageDirective('src=x.png spread=12', span: span)!;
      expect(i.spread, '12');
    });

    test('bordertrbl (sides letters)', () {
      final i = parseImageDirective(
        'src=x.png bordertrbl=tb',
        span: span,
      )!;
      expect(i.bordertrbl, 'tb');
    });

    test('center deprecated alias', () {
      final i = parseImageDirective('src=x.png center=1', span: span)!;
      expect(i.center, '1');
    });

    test('chord attribute', () {
      final i = parseImageDirective('chord=Cmaj7', span: span)!;
      expect(i.chord, 'Cmaj7');
    });

    test('type attribute', () {
      final i = parseImageDirective('src=x.png type=svg', span: span)!;
      expect(i.type, 'svg');
    });

    test('persist and omit', () {
      final i = parseImageDirective(
        'src=x.png persist=1 omit=0',
        span: span,
      )!;
      expect(i.persist, '1');
      expect(i.omit, '0');
    });
  });

  group('ImageAnchor enum (Song.pm:1917)', () {
    test('all six allowed values parse', () {
      const allowed = [
        'paper',
        'page',
        'allpages',
        'column',
        'float',
        'line',
      ];
      for (final v in allowed) {
        final i = parseImageDirective('src=x.png anchor=$v', span: span)!;
        expect(i.anchor, v, reason: 'raw anchor for $v');
        expect(i.anchorEnum?.name, v, reason: 'enum anchor for $v');
      }
    });

    test('unknown anchor value -> anchorEnum null but anchor preserved', () {
      final i = parseImageDirective('src=x.png anchor=ufo', span: span)!;
      expect(i.anchor, 'ufo');
      expect(i.anchorEnum, isNull);
    });
  });
}
