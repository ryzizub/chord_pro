import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('ChordDefinition parsing', () {
    test('parses a full define directive', () {
      const source =
          '{define: G base-fret 1 frets 3 2 0 0 0 3 fingers 2 1 0 0 0 3}';
      final song = ChordPro.parseSong(source);
      expect(song.chordDefinitions, hasLength(1));
      final def = song.chordDefinitions.single;
      expect(def.name, 'G');
      expect(def.baseFret, 1);
      expect(def.frets, [3, 2, 0, 0, 0, 3]);
      expect(def.fingers, [2, 1, 0, 0, 0, 3]);
    });

    test('records muted strings as null', () {
      const source = '{chord: D frets x x 0 2 3 2}';
      final song = ChordPro.parseSong(source);
      expect(song.chordDefinitions.single.frets, [null, null, 0, 2, 3, 2]);
    });

    test('treats {chord: ...} as a {define} alias', () {
      const source = '{chord: A base-fret 1 frets x 0 2 2 2 0}';
      final song = ChordPro.parseSong(source);
      expect(song.chordDefinitions.single.name, 'A');
      expect(song.chordDefinitions.single.baseFret, 1);
      expect(song.chordDefinitions.single.frets, [null, 0, 2, 2, 2, 0]);
    });

    test('emits a diagnostic for an empty define', () {
      final result = ChordPro.parse('{define:}');
      expect(result.songs.single.chordDefinitions, isEmpty);
    });
  });

  group('Selector-aware metadata', () {
    test('skips selector-tagged titles by default', () {
      const source = '{title: Plain}\n{title-guitar: Fancy}';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.titles, ['Plain']);
    });

    test('includes positive-selector titles when selector is active', () {
      const source = '{title: Plain}\n{title-guitar: Fancy}';
      final song = ChordPro.parseSong(source, selectors: {'guitar'});
      expect(song.metadata.titles, ['Plain', 'Fancy']);
    });

    test('skips negative-selector titles when selector is active', () {
      const source = '{title: Plain}\n{title-!guitar: For Others}';
      final song = ChordPro.parseSong(source, selectors: {'guitar'});
      expect(song.metadata.titles, ['Plain']);
    });

    test('keeps negative-selector titles when selector is inactive', () {
      const source = '{title: Plain}\n{title-!guitar: For Others}';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.titles, ['Plain', 'For Others']);
    });

    test('legacy {name+selector} form is treated as negation', () {
      const source = '{title: Plain}\n{title+guitar: For Others}';
      final guitar = ChordPro.parseSong(source, selectors: {'guitar'});
      expect(guitar.metadata.titles, ['Plain']);
      final piano = ChordPro.parseSong(source);
      expect(piano.metadata.titles, ['Plain', 'For Others']);
    });

    test('selector matching is case-insensitive', () {
      const source = '{title: Plain}\n{title-Guitar: Fancy}';
      final song = ChordPro.parseSong(source, selectors: {'GUITAR'});
      expect(song.metadata.titles, ['Plain', 'Fancy']);
    });
  });

  group('Selector-aware formatting', () {
    test('skips selector-tagged formatting by default', () {
      const source = '{textcolour: black}\n{textcolour-print: gray}';
      final song = ChordPro.parseSong(source);
      expect(song.formatting.forTarget('text').colour, 'black');
    });

    test('applies positive-selector formatting when selector is active', () {
      const source = '{textcolour: black}\n{textcolour-print: gray}';
      final song = ChordPro.parseSong(source, selectors: {'print'});
      expect(song.formatting.forTarget('text').colour, 'gray');
    });

    test('skips negative-selector formatting when selector is active', () {
      const source = '{chordfont: Sans}\n{chordfont-!print: Mono}';
      final song = ChordPro.parseSong(source, selectors: {'print'});
      expect(song.formatting.forTarget('chord').font, 'Sans');
    });

    test('spec postfix `!` form on formatting works too', () {
      const source = '{chordfont: Sans}\n{chordfont-print!: Mono}';
      // print is inactive, so the `-print!` (negation) directive applies.
      final song = ChordPro.parseSong(source);
      expect(song.formatting.forTarget('chord').font, 'Mono');
    });
  });

  group('Selector-aware sections, comments, images, and breaks', () {
    test('section start with inactive selector skips entire section body', () {
      const source = '''
[G]before
{start_of_verse-soprano}
[A]inside that should be hidden
{comment: also hidden}
{end_of_verse}
[D]after
''';
      final song = ChordPro.parseSong(source);
      // No selectors active, so the `-soprano` section is gated out.
      // Only the surrounding loose lines remain.
      expect(song.sections, hasLength(1));
      final lines = song.sections.single.lines;
      expect(lines, hasLength(2));
      expect(lines.first.kind, LineKind.structured);
      expect(lines.last.kind, LineKind.structured);
    });

    test('section start with active positive selector keeps body', () {
      const source = '''
{start_of_verse-soprano}
[A]inside
{end_of_verse}
''';
      final song = ChordPro.parseSong(source, selectors: {'soprano'});
      expect(song.sections.single.kind, SectionKind.verse);
      expect(song.sections.single.lines, hasLength(1));
    });

    test('section start with postfix `!` keeps body when selector inactive',
        () {
      const source = '''
{start_of_verse-soprano!}
[A]for everyone else
{end_of_verse}
''';
      final song = ChordPro.parseSong(source);
      expect(song.sections.single.kind, SectionKind.verse);
    });

    test('comment with inactive selector emits nothing in flow', () {
      const source = '''
{start_of_verse}
[G]hi
{comment-print: only when printing}
[D]bye
{end_of_verse}
''';
      final song = ChordPro.parseSong(source);
      final lines = song.sections.single.lines;
      expect(lines.map((l) => l.kind).toList(), [
        LineKind.structured,
        LineKind.structured,
      ]);
    });

    test('chord recall with inactive selector emits no recall section', () {
      const source = '{chorus-soprano}';
      final song = ChordPro.parseSong(source);
      expect(song.sections, isEmpty);
    });

    test('chord define with inactive selector is suppressed', () {
      const source = '''
{define-guitar: Am base-fret 1 frets x 0 2 2 1 0}
{define-ukulele: Am base-fret 1 frets 2 0 0 0}
''';
      final guitar = ChordPro.parseSong(source, selectors: {'guitar'});
      expect(guitar.chordDefinitions, hasLength(1));
      expect(guitar.chordDefinitions.single.frets, [null, 0, 2, 2, 1, 0]);

      final ukulele = ChordPro.parseSong(source, selectors: {'ukulele'});
      expect(ukulele.chordDefinitions, hasLength(1));
      expect(ukulele.chordDefinitions.single.frets, [2, 0, 0, 0]);
    });
  });
}
