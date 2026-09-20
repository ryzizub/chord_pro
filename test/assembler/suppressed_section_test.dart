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
      expect(result.songs.first.sections, isEmpty);
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
        for (final section in result.songs.first.sections) ...section.lines,
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
      expect(song.sections, isEmpty);
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
