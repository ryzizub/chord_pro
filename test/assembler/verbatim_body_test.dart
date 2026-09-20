import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Verbatim environment bodies', () {
    test('a `{`-leading line inside a tab stays verbatim', () {
      const source = '{start_of_tab}\n'
          '{riff x2}\n'
          'e|--0--|\n'
          '{end_of_tab}\n';
      final result = ChordPro.parse(source);
      final song = result.songs.single;
      final tab = song.sections.single;

      expect(tab.kind, SectionKind.tab);
      expect(tab.lines.every((l) => l.kind == LineKind.verbatim), isTrue);
      expect(tab.lines.map((l) => l.verbatim).toList(), [
        '{riff x2}',
        'e|--0--|',
      ]);
      expect(
        song.directives.map((d) => d.name).toList(),
        ['start_of_tab', 'end_of_tab'],
        reason: 'a body line is not a directive and must not be recorded',
      );
      expect(result.diagnostics, isEmpty);
    });

    test(r'a LilyPond `{\key …}` body line stays verbatim', () {
      const source = '{start_of_ly}\n'
          r'{\key c \major}'
          '\n'
          'c d e f\n'
          '{end_of_ly}\n';
      final song = ChordPro.parseSong(source);
      final ly = song.sections.single;

      expect(ly.kind, SectionKind.ly);
      expect(ly.lines.map((l) => l.verbatim).toList(), [
        r'{\key c \major}',
        'c d e f',
      ]);
    });

    test('every verbatim environment keeps `{`-leading body lines', () {
      const environments = {
        'tab': SectionKind.tab,
        'grid': SectionKind.grid,
        'abc': SectionKind.abc,
        'ly': SectionKind.ly,
        'svg': SectionKind.svg,
        'textblock': SectionKind.textblock,
        'grille': SectionKind.grille,
      };

      for (final entry in environments.entries) {
        final name = entry.key;
        final source = '{start_of_$name}\n'
            '{repeat 2}\n'
            '{end_of_$name}\n';
        final result = ChordPro.parse(source);
        final section = result.songs.single.sections.single;

        expect(section.kind, entry.value, reason: name);
        expect(
          section.lines.map((l) => l.verbatim).toList(),
          ['{repeat 2}'],
          reason: name,
        );
        expect(
          result.songs.single.directives.map((d) => d.name).toList(),
          ['start_of_$name', 'end_of_$name'],
          reason: name,
        );
        expect(result.diagnostics, isEmpty, reason: name);
      }
    });

    test('a comment directive inside a tab is body text, not a comment line',
        () {
      const source = '{start_of_tab}\n'
          '{comment: not a comment here}\n'
          '{end_of_tab}\n';
      final song = ChordPro.parseSong(source);
      final tab = song.sections.single;

      expect(tab.lines.single.kind, LineKind.verbatim);
      expect(tab.lines.single.verbatim, '{comment: not a comment here}');
    });

    test('a nested `{start_of_tab}` inside a tab is body text', () {
      const source = '{start_of_tab}\n'
          '{start_of_tab}\n'
          'e|--0--|\n'
          '{end_of_tab}\n';
      final result = ChordPro.parse(source);
      final tab = result.songs.single.sections.single;

      expect(tab.lines.map((l) => l.verbatim).toList(), [
        '{start_of_tab}',
        'e|--0--|',
      ]);
      expect(result.diagnostics, isEmpty);
    });

    test('a non-matching `{end_of_…}` inside a tab is body text', () {
      const source = '{start_of_tab}\n'
          '{end_of_grid}\n'
          'e|--0--|\n'
          '{end_of_tab}\n';
      final result = ChordPro.parse(source);
      final tab = result.songs.single.sections.single;

      expect(tab.kind, SectionKind.tab);
      expect(tab.lines.map((l) => l.verbatim).toList(), [
        '{end_of_grid}',
        'e|--0--|',
      ]);
      expect(result.diagnostics, isEmpty);
    });

    test('the short-form `{eot}` still closes a tab opened with {sot}', () {
      const source = '{sot}\n{riff}\n{eot}\nafter\n';
      final result = ChordPro.parse(source);
      final song = result.songs.single;

      expect(song.sections.first.kind, SectionKind.tab);
      expect(song.sections.first.lines.single.verbatim, '{riff}');
      expect(song.sections.last.kind, SectionKind.loose);
      expect(result.diagnostics, isEmpty);
    });

    test('`{new_song}` inside a verbatim body does not split the song', () {
      const source = '{start_of_tab}\n{new_song}\n{end_of_tab}\n';
      final result = ChordPro.parse(source);

      expect(result.songs, hasLength(1));
      expect(
        result.songs.single.sections.single.lines.single.verbatim,
        '{new_song}',
      );
    });

    test('structured environments still parse directives in their body', () {
      const source = '{start_of_verse}\n{comment: still a comment}\n'
          '{end_of_verse}\n';
      final song = ChordPro.parseSong(source);
      final verse = song.sections.single;

      expect(verse.kind, SectionKind.verse);
      expect(verse.lines.single.kind, LineKind.comment);
      expect(verse.lines.single.comment, 'still a comment');
    });

    test('a `{`-leading line is verbatim even with an open loose section', () {
      const source = 'lyric line\n'
          '{start_of_tab}\n'
          '{riff x2}\n'
          '{end_of_tab}\n';
      final result = ChordPro.parse(source);
      final song = result.songs.single;

      expect(song.sections, hasLength(2));
      expect(song.sections.first.kind, SectionKind.loose);
      expect(song.sections.last.kind, SectionKind.tab);
      expect(song.sections.last.lines.single.verbatim, '{riff x2}');
      expect(result.diagnostics, isEmpty);
    });

    test('a selector-suppressed verbatim environment keeps its body verbatim',
        () {
      const source = '{start_of_tab-guitar}\n'
          '{riff x2}\n'
          'e|--0--|\n'
          '{end_of_tab}\n';
      final result = ChordPro.parse(source);
      final song = result.songs.single;
      final tab = song.sections.single;

      expect(tab.kind, SectionKind.tab);
      expect(tab.isSelectorSuppressed, isTrue);
      expect(song.activeSections, isEmpty);
      expect(tab.lines.map((l) => l.verbatim).toList(), [
        '{riff x2}',
        'e|--0--|',
      ]);
      expect(
        song.directives.map((d) => d.name).toList(),
        ['start_of_tab', 'end_of_tab'],
        reason: 'the suppressed body holds no directives either',
      );
    });
  });
}
