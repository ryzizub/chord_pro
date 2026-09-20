import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

const _source = '''
{title: Song}
{artist: Someone}
{key: G}
{define: G base-fret 1 frets 3 2 0 0 0 3}

{start_of_verse: Verse 1}
[G]Mama, take this [D]badge off of [Am]me
{comment: aside}
{end_of_verse}

{start_of_tab}
e|---0---|
{end_of_tab}
''';

void main() {
  group('value equality', () {
    test('two parses of the same source compare equal', () {
      expect(ChordPro.parseSong(_source), ChordPro.parseSong(_source));
      expect(
        ChordPro.parseSong(_source).hashCode,
        ChordPro.parseSong(_source).hashCode,
      );
      expect(ChordPro.parse(_source), ChordPro.parse(_source));
    });

    test('a different source compares unequal', () {
      expect(
        ChordPro.parseSong(_source),
        isNot(ChordPro.parseSong(_source.replaceAll('[G]', '[A]'))),
      );
    });

    test('chords compare by value', () {
      expect(Chord.tryParse('Am'), Chord.tryParse('Am'));
      expect(Chord.tryParse('Am').hashCode, Chord.tryParse('Am').hashCode);
      expect(Chord.tryParse('Am'), isNot(Chord.tryParse('A')));
      expect(Chord.tryParse('G/B'), Chord.tryParse('G/B'));
      expect(Chord.tryParse('G/B'), isNot(Chord.tryParse('G/D')));
    });

    test('the AST parts compare by value', () {
      final a = ChordPro.parseSong(_source);
      final b = ChordPro.parseSong(_source);
      expect(a.metadata, b.metadata);
      expect(a.sections.first, b.sections.first);
      expect(a.sections.first.lines.first, b.sections.first.lines.first);
      expect(a.directives.first, b.directives.first);
      expect(a.chordDefinitions.first, b.chordDefinitions.first);
      expect(a.formatting, b.formatting);
      expect(
        a.sections.first.lines.first.tokens.first,
        b.sections.first.lines.first.tokens.first,
      );
    });

    test('equal songs can be used as set and map keys', () {
      final set = {ChordPro.parseSong(_source), ChordPro.parseSong(_source)};
      expect(set, hasLength(1));
    });

    test('a transposed song equals the same song parsed transposed', () {
      final moved = ChordPro.parseSong('[G]hi').transposed(2);
      final direct = ChordPro.parseSong('[A]hi');
      expect(
        moved.sections.first.lines.first.tokens,
        direct.sections.first.lines.first.tokens,
      );
    });

    test('SourceSpan and Diagnostic compare by value', () {
      const a = SourceSpan(line: 2, column: 3, length: 4);
      const b = SourceSpan(line: 2, column: 3, length: 4);
      expect(a, b);
      expect(a, isNot(const SourceSpan(line: 2, column: 3, length: 5)));
      const d = Diagnostic(
        severity: DiagnosticSeverity.warning,
        code: DiagnosticCode.strayEnd,
        message: 'x',
        span: a,
      );
      expect(
        d,
        const Diagnostic(
          severity: DiagnosticSeverity.warning,
          code: DiagnosticCode.strayEnd,
          message: 'x',
          span: b,
        ),
      );
    });
  });

  group('the attribute value types compare by value', () {
    Section sectionOf(String source) =>
        ChordPro.parseSong(source).sections.first;

    test('GridAttributes', () {
      const grid = '{start_of_grid: shape="1+4x4+1" cc="Riff:C G"}\n'
          '| C |\n{end_of_grid}';
      final a = sectionOf(grid).gridAttributes!;
      final b = sectionOf(grid).gridAttributes!;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.ccProgression, ['C', 'G']);
      expect(
        a,
        isNot(
          sectionOf('{start_of_grid: 2x2}\n| C |\n{end_of_grid}')
              .gridAttributes,
        ),
      );
    });

    test('TextblockAttributes', () {
      const block = '{start_of_textblock: width=50% flush=center '
          'textcolor=red background=grey border=1 id=intro href=#top '
          'title=T align=left anchor=page x=1 y=2 padding=3 vflush=top '
          'textstyle=italic textsize=12 textspacing=1.5 omit=no '
          'persist=yes bordertrbl=tb}\nhi\n{end_of_textblock}';
      final a = sectionOf(block).textblockAttributes!;
      final b = sectionOf(block).textblockAttributes!;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          sectionOf('{start_of_textblock: width=10%}\nhi\n'
                  '{end_of_textblock}')
              .textblockAttributes,
        ),
      );
    });

    test('DiagramsSetting', () {
      expect(
        ChordPro.parseSong('{diagrams: top}').diagrams,
        ChordPro.parseSong('{diagrams: top}').diagrams,
      );
      expect(
        ChordPro.parseSong('{diagrams: top}').diagrams,
        isNot(ChordPro.parseSong('{diagrams: right}').diagrams),
      );
      expect(
        ChordPro.parseSong('{diagrams: top}').diagrams.hashCode,
        ChordPro.parseSong('{diagrams: top}').diagrams.hashCode,
      );
    });

    test('ImageDirective', () {
      const image = '{image: src="cover.png" width=200 anchor=page}';
      ImageDirective imageOf(String source) =>
          ChordPro.parseSong(source).sections.first.lines.first.image!;
      expect(imageOf(image), imageOf(image));
      expect(imageOf(image).hashCode, imageOf(image).hashCode);
      expect(
        imageOf(image),
        isNot(imageOf('{image: src="other.png"}')),
      );
    });

    test('FormattingProps and FormattingSettings', () {
      const source = '{textfont: Times}\n{textsize: 12}\n{textcolour: red}';
      final a = ChordPro.parseSong(source).formatting;
      final b = ChordPro.parseSong(source).formatting;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.forTarget('text'), b.forTarget('text'));
      expect(
        a.forTarget('text'),
        isNot(const FormattingProps(font: 'Times')),
      );
      expect(a, isNot(ChordPro.parseSong('{textfont: Arial}').formatting));
    });

    test('ChordDefinition', () {
      // No `%{…}` in the format string: the directive parser closes on
      // the first unescaped `}` (a documented limitation).
      const define = '{define: G base-fret 1 frets 3 2 0 0 0 3 '
          'fingers 2 1 - - - 3 keys 0 4 7 display Gmaj format "chord" '
          'copy X copyall Y diagram on}';
      final a = ChordPro.parseSong(define).chordDefinitions.single;
      final b = ChordPro.parseSong(define).chordDefinitions.single;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          ChordPro.parseSong('{define: G base-fret 2}').chordDefinitions.single,
        ),
      );
    });

    test('RawLine and the tokens scan produces', () {
      const line = RawLine(number: 1, text: '[C]hi');
      expect(line, const RawLine(number: 1, text: '[C]hi'));
      expect(line.hashCode, const RawLine(number: 1, text: '[C]hi').hashCode);
      expect(line, isNot(const RawLine(number: 2, text: '[C]hi')));
      expect(line.toString(), contains('[C]hi'));
      expect(scan('[C]hi'), [line]);
    });

    test('every inline token kind', () {
      const source = '[C]hi [*note] [^] [] {c: x} plain';
      List<InlineToken> tokensOf() =>
          ChordPro.parseSong(source).sections.first.lines.first.tokens;
      expect(tokensOf(), tokensOf());
      for (final pair in [tokensOf(), tokensOf()].first.asMap().entries) {
        expect(pair.value, tokensOf()[pair.key]);
        expect(pair.value.hashCode, tokensOf()[pair.key].hashCode);
      }
      expect(
        tokensOf().whereType<TextToken>().first,
        isNot(
          const TextToken(
            text: 'different',
            span: SourceSpan(line: 1, column: 1, length: 9),
          ),
        ),
      );
    });

    test('DirectiveMatch', () {
      const line = RawLine(number: 1, text: '{title: x} rest');
      expect(parseDirectiveAt(line, 0), parseDirectiveAt(line, 0));
      expect(
        parseDirectiveAt(line, 0).hashCode,
        parseDirectiveAt(line, 0).hashCode,
      );
      expect(
        parseDirectiveAt(line, 0),
        isNot(
          parseDirectiveAt(
            const RawLine(number: 1, text: '{title: y} rest'),
            0,
          ),
        ),
      );
    });
  });

  group('the parsed AST is not mutable in place', () {
    final song = ChordPro.parseSong(_source);

    test('sections, lines and tokens are unmodifiable', () {
      expect(song.sections.clear, throwsUnsupportedError);
      expect(song.sections.first.lines.clear, throwsUnsupportedError);
      expect(
        song.sections.first.lines.first.tokens.clear,
        throwsUnsupportedError,
      );
      expect(song.directives.clear, throwsUnsupportedError);
      expect(song.chordDefinitions.clear, throwsUnsupportedError);
    });

    test('chord definition lists are unmodifiable', () {
      final def = song.chordDefinitions.first;
      expect(() => def.frets.add(0), throwsUnsupportedError);
      expect(() => def.fingers.add(0), throwsUnsupportedError);
      expect(() => def.keys.add(0), throwsUnsupportedError);
    });

    test('section attributes and metadata maps are unmodifiable', () {
      expect(
        () => song.sections.first.attributes['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(song.metadata.titles.clear, throwsUnsupportedError);
      expect(song.metadata.other.clear, throwsUnsupportedError);
    });

    test('a transposed song is unmodifiable too', () {
      final moved = song.transposed(2);
      expect(moved.sections.clear, throwsUnsupportedError);
      expect(moved.sections.first.lines.clear, throwsUnsupportedError);
      expect(
        moved.sections.first.lines.first.tokens.clear,
        throwsUnsupportedError,
      );
    });
  });
}
