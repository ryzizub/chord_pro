import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Assembler sections', () {
    test('wraps loose lines in a loose section', () {
      final song = ChordPro.parseSong('hello world');
      expect(song.sections, hasLength(1));
      expect(song.sections.single.kind, SectionKind.loose);
      expect(song.sections.single.lines, hasLength(1));
      final tokens = song.sections.single.lines.single.tokens;
      expect(tokens, hasLength(1));
      expect((tokens.single as TextToken).text, 'hello world');
    });

    test('captures verse with label', () {
      const source = '''
{start_of_verse: Verse 1}
[G]line one
[D]line two
{end_of_verse}
''';
      final song = ChordPro.parseSong(source);
      expect(song.sections, hasLength(1));
      final section = song.sections.single;
      expect(section.kind, SectionKind.verse);
      expect(section.label, 'Verse 1');
      expect(section.lines, hasLength(2));
    });

    test('captures chorus via short form {soc}/{eoc}', () {
      const source = '{soc}\n[C]hey\n{eoc}';
      final song = ChordPro.parseSong(source);
      expect(song.sections.single.kind, SectionKind.chorus);
    });

    test('captures tab verbatim', () {
      const source = '''
{start_of_tab}
e|--0--|
B|--1--|
{end_of_tab}
''';
      final song = ChordPro.parseSong(source);
      final section = song.sections.single;
      expect(section.kind, SectionKind.tab);
      expect(section.lines.every((l) => l.isVerbatim), isTrue);
      expect(section.lines.first.verbatim, 'e|--0--|');
    });

    test('bare {chorus} is a chorus recall', () {
      final song = ChordPro.parseSong('{chorus}');
      expect(song.sections, hasLength(1));
      expect(song.sections.single.kind, SectionKind.chorus);
      expect(song.sections.single.isChorusRecall, isTrue);
      expect(song.sections.single.lines, isEmpty);
    });

    test('stray end emits a diagnostic and no section', () {
      final result = ChordPro.parse('{end_of_verse}');
      expect(result.songs.single.sections, isEmpty);
      expect(result.diagnostics, hasLength(1));
      expect(result.diagnostics.single.severity, DiagnosticSeverity.warning);
    });

    test('unterminated environment warns and auto-closes at EOF', () {
      final result = ChordPro.parse('{start_of_verse}\nline\n');
      expect(result.songs.single.sections, hasLength(1));
      expect(result.diagnostics, hasLength(1));
    });

    test('custom environment is preserved with customKind', () {
      const source = '{start_of_intro}\nline\n{end_of_intro}';
      final song = ChordPro.parseSong(source);
      expect(song.sections.single.kind, SectionKind.custom);
      expect(song.sections.single.customKind, 'intro');
    });

    test('directives and loose content split across multiple sections', () {
      const source = '''
hello
{start_of_chorus}
[G]bright
{end_of_chorus}
world
''';
      final song = ChordPro.parseSong(source);
      expect(song.sections.map((s) => s.kind).toList(), [
        SectionKind.loose,
        SectionKind.chorus,
        SectionKind.loose,
      ]);
    });

    test('comment-family directives become comment lines in the section', () {
      const source = '''
{start_of_verse}
[G]hello
{comment: lookout, breakdown}
{ci: gentle now}
{cb: BOX}
{highlight: emphasised}
[D]world
{end_of_verse}
''';
      final song = ChordPro.parseSong(source);
      final lines = song.sections.single.lines;
      expect(lines.map((l) => l.kind).toList(), [
        LineKind.structured,
        LineKind.comment,
        LineKind.comment,
        LineKind.comment,
        LineKind.comment,
        LineKind.structured,
      ]);
      expect(lines[1].comment, 'lookout, breakdown');
      expect(lines[1].commentStyle, CommentStyle.plain);
      expect(lines[2].commentStyle, CommentStyle.italic);
      expect(lines[3].commentStyle, CommentStyle.box);
      expect(lines[4].commentStyle, CommentStyle.highlight);
    });

    test('layout-break directives become layoutBreak lines', () {
      const source = '''
[G]hello
{new_page}
{column_break}
{npp}
''';
      final song = ChordPro.parseSong(source);
      final lines = song.sections.single.lines;
      expect(lines.map((l) => l.kind).toList(), [
        LineKind.structured,
        LineKind.layoutBreak,
        LineKind.layoutBreak,
        LineKind.layoutBreak,
      ]);
      expect(lines[1].layoutBreak, LayoutBreak.newPage);
      expect(lines[2].layoutBreak, LayoutBreak.columnBreak);
      expect(lines[3].layoutBreak, LayoutBreak.newPhysicalPage);
    });

    test('{columns: N} populates metadata.columns', () {
      final song = ChordPro.parseSong('{columns: 2}');
      expect(song.metadata.columns, 2);
    });

    test('{col: N} short form populates metadata.columns', () {
      final song = ChordPro.parseSong('{col: 3}');
      expect(song.metadata.columns, 3);
    });

    test('# file-comment lines are ignored', () {
      const source = '''
# this is a comment
{title: Sample}
# another note
hello world
''';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.titles, ['Sample']);
      expect(song.sections, hasLength(1));
      expect(song.sections.single.lines, hasLength(1));
      expect(
        (song.sections.single.lines.single.tokens.single as TextToken).text,
        'hello world',
      );
    });
  });
}
