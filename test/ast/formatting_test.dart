import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('FormattingSettings', () {
    test('collects font/size/colour overrides per target', () {
      const source = '''
{chordfont: Times}
{chordsize: 12}
{chordcolour: blue}
{textfont: Helvetica}
{titlecolour: red}
''';
      final song = ChordPro.parseSong(source);
      final chord = song.formatting.forTarget('chord');
      expect(chord.font, 'Times');
      expect(chord.size, '12');
      expect(chord.colour, 'blue');
      final text = song.formatting.forTarget('text');
      expect(text.font, 'Helvetica');
      final title = song.formatting.forTarget('title');
      expect(title.colour, 'red');
    });

    test('accepts short forms (cf/cs/tf/ts)', () {
      const source = '{cf: Mono}\n{cs: 14}\n{tf: Serif}\n{ts: 11}';
      final song = ChordPro.parseSong(source);
      expect(song.formatting.forTarget('chord').font, 'Mono');
      expect(song.formatting.forTarget('chord').size, '14');
      expect(song.formatting.forTarget('text').font, 'Serif');
      expect(song.formatting.forTarget('text').size, '11');
    });

    test('accepts both colour and color spellings', () {
      const source = '{chordcolor: green}';
      final song = ChordPro.parseSong(source);
      expect(song.formatting.forTarget('chord').colour, 'green');
    });

    test('isEmpty when no formatting directives are declared', () {
      final song = ChordPro.parseSong('{title: Plain}');
      expect(song.formatting.isEmpty, isTrue);
    });
  });
}
