import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('selector-suppressed sections', () {
    test('a song boundary ends the suppression', () {
      // Splitting songs is structural, so `{new_song}` is never
      // conditional: a suppressed section that forgot its end directive
      // must not swallow the songs that follow it.
      final result = ChordPro.parse('''
{title: One}
{start_of_chorus-guitar}
suppressed
{new_song}
{title: Two}
[C]visible lyric
''');

      expect(result.songs, hasLength(2));
      expect(result.songs.first.metadata.titles, ['One']);
      expect(result.songs.first.activeSections, isEmpty);
      expect(result.songs.last.metadata.titles, ['Two']);
      expect(result.songs.last.sections, hasLength(1));
      expect(
        result.diagnostics.map((d) => d.code),
        contains(DiagnosticCode.unterminatedSuppressedSection),
      );
    });

    test('a nested section of the same kind does not end the suppression', () {
      final result = ChordPro.parse('''
{start_of_chorus-guitar}
suppressed
{start_of_chorus}
still suppressed
{end_of_chorus}
also suppressed
{end_of_chorus}
[C]visible
''');

      final lines = [
        for (final section in result.songs.first.activeSections)
          ...section.lines,
      ];
      final text = lines
          .expand((l) => l.tokens)
          .whereType<TextToken>()
          .map((t) => t.text)
          .join();
      expect(text, 'visible');
      expect(result.diagnostics, isEmpty);
    });

    test('an unterminated suppressed section is reported at end of song', () {
      final result = ChordPro.parse('{start_of_chorus-guitar}\nabc\n');

      expect(result.diagnostics, hasLength(1));
      expect(
        result.diagnostics.single.code,
        DiagnosticCode.unterminatedSuppressedSection,
      );
      // The span points at the start directive that opened the section.
      expect(result.diagnostics.single.span.line, 1);
    });

    test('suppressed directives still reach the lossless directive stream', () {
      final song = ChordPro.parseSong('''
{start_of_chorus-guitar}
suppressed
{comment: hidden}
{end_of_chorus}
''');

      expect(
        song.directives.map((d) => d.name),
        ['start_of_chorus', 'comment', 'end_of_chorus'],
      );
      expect(song.activeSections, isEmpty);
    });

    test('the suppressed body is kept as a flagged section (#36)', () {
      // Regression: the body used to land nowhere, so re-emitting from
      // the AST silently dropped every line between the markers.
      final song = ChordPro.parseSong('{start_of_verse-guitar}\n'
          '[C]body\n'
          '{end_of_verse}\n');

      expect(song.sections, hasLength(1));
      final section = song.sections.single;
      expect(section.kind, SectionKind.verse);
      expect(section.isSelectorSuppressed, isTrue);
      expect(section.lines, hasLength(1));
      expect(
        section.lines.single.tokens.whereType<TextToken>().single.text,
        'body',
      );
      expect(
        section.lines.single.tokens.whereType<ChordToken>().single.raw,
        'C',
      );
      // It is not part of what a selector-honouring renderer outputs.
      expect(song.activeSections, isEmpty);
      expect(
        song.directives.map((d) => d.name),
        ['start_of_verse', 'end_of_verse'],
      );
    });

    test(
        'a suppressed section carries the same label, attributes and body '
        'as the applying one', () {
      const source = '{start_of_verse-guitar: label="V1" foo=bar}\n'
          '[C]body\n'
          '\n'
          '[G]more\n'
          '{end_of_verse}\n';

      final suppressed = ChordPro.parseSong(source).sections.single;
      final applied =
          ChordPro.parseSong(source, selectors: {'guitar'}).sections.single;

      expect(suppressed.isSelectorSuppressed, isTrue);
      expect(applied.isSelectorSuppressed, isFalse);
      expect(suppressed.label, 'V1');
      expect(suppressed.attributes, {'foo': 'bar'});
      expect(suppressed.lines, applied.lines);
      expect(suppressed.span, applied.span);
    });

    test('a suppressed verbatim section keeps its body verbatim', () {
      final song = ChordPro.parseSong('{start_of_tab-guitar}\n'
          'e|--[not a chord]--|\n'
          '{end_of_tab}\n');

      final section = song.sections.single;
      expect(section.kind, SectionKind.tab);
      expect(section.isSelectorSuppressed, isTrue);
      expect(section.lines.single.kind, LineKind.verbatim);
      expect(section.lines.single.verbatim, 'e|--[not a chord]--|');
    });

    test('a suppressed section keeps its place in source order', () {
      final song = ChordPro.parseSong('[C]before\n'
          '{start_of_chorus-guitar}\n'
          'hidden\n'
          '{end_of_chorus}\n'
          '[G]after\n');

      expect(
        song.sections.map((s) => s.kind),
        [SectionKind.loose, SectionKind.chorus, SectionKind.loose],
      );
      expect(song.sections[1].isSelectorSuppressed, isTrue);
      expect(
        song.activeSections.map((s) => s.kind),
        [SectionKind.loose, SectionKind.loose],
      );
    });

    test('an unterminated suppressed section still yields its body', () {
      final result = ChordPro.parse('{start_of_chorus-guitar}\nabc\n');

      final section = result.songs.single.sections.single;
      expect(section.isSelectorSuppressed, isTrue);
      expect(section.lines, hasLength(1));
    });

    test('a nested same-kind section is captured as one suppressed body', () {
      final song = ChordPro.parseSong('{start_of_chorus-guitar}\n'
          'one\n'
          '{start_of_chorus}\n'
          'two\n'
          '{end_of_chorus}\n'
          'three\n'
          '{end_of_chorus}\n');

      final section = song.sections.single;
      expect(section.isSelectorSuppressed, isTrue);
      expect(
        section.lines
            .expand((l) => l.tokens)
            .whereType<TextToken>()
            .map((t) => t.text),
        ['one', 'two', 'three'],
      );
    });

    test('transposing carries the suppression flag and the body', () {
      final song = ChordPro.parseSong('{start_of_verse-guitar}\n'
              '[C]body\n'
              '{end_of_verse}\n')
          .transposed(2);

      final section = song.sections.single;
      expect(section.isSelectorSuppressed, isTrue);
      expect(
        section.lines.single.tokens.whereType<ChordToken>().single.raw,
        'D',
      );
    });

    test('sections differing only in suppression are not equal', () {
      const source = '{start_of_verse-guitar}\n[C]body\n{end_of_verse}\n';

      final suppressed = ChordPro.parseSong(source).sections.single;
      final applied =
          ChordPro.parseSong(source, selectors: {'guitar'}).sections.single;

      expect(suppressed, isNot(applied));
      expect(suppressed.hashCode, isNot(applied.hashCode));
    });

    test(
        'a suppressed start auto-closes an enclosing section, exactly as '
        'an applying one does', () {
      const source = '{start_of_verse}\n'
          '[C]v\n'
          '{start_of_chorus-guitar}\n'
          'hidden\n'
          '{end_of_chorus}\n'
          '[G]more\n'
          '{end_of_verse}\n';

      final suppressed = ChordPro.parse(source);
      final applied = ChordPro.parse(source, selectors: {'guitar'});

      // Same sections and same diagnostics either way; only the flag on
      // the chorus differs.
      expect(
        suppressed.songs.single.sections.map((s) => s.kind),
        [SectionKind.verse, SectionKind.chorus, SectionKind.loose],
      );
      expect(
        applied.songs.single.sections.map((s) => s.kind),
        suppressed.songs.single.sections.map((s) => s.kind),
      );
      expect(suppressed.songs.single.sections[1].isSelectorSuppressed, isTrue);
      expect(
        suppressed.diagnostics.map((d) => d.code),
        [DiagnosticCode.nestedSection, DiagnosticCode.strayEnd],
      );
      expect(
        applied.diagnostics.map((d) => d.code),
        suppressed.diagnostics.map((d) => d.code),
      );
    });

    test('an active selector leaves the section in place', () {
      final song = ChordPro.parseSong(
        '{start_of_chorus-guitar}\n[C]hi\n{end_of_chorus}',
        selectors: {'guitar'},
      );

      expect(song.sections, hasLength(1));
      expect(song.sections.single.kind, SectionKind.chorus);
    });
  });
}
