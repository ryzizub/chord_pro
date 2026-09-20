/// Property test for the parser's two structural invariants.
///
/// `ChordPro.parse` is documented as total: it recovers from anything and
/// always yields at least one song, so `result.songs.first` is safe for
/// every caller. Unit tests can only cover the malformed inputs someone
/// thought of; this generates them instead, from an alphabet weighted
/// towards the characters that actually drive the state machine.
///
/// The seed is fixed so a failure is reproducible; print `seed` from a
/// failing run to replay it.
library;

import 'dart:math';

import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

/// Fragments weighted towards the syntax that steers the assembler.
const _fragments = <String>[
  '[',
  ']',
  '{',
  '}',
  r'\',
  '|',
  '*',
  '^',
  ':',
  '=',
  '"',
  "'",
  '-',
  '+',
  '#',
  '/',
  '~',
  '%',
  '.',
  ',',
  ' ',
  '\t',
  '\n',
  '\r',
  '\r\n',
  'a',
  'G',
  '7',
  'é',
  '𝄞',
  '\u0000',
  r'\u',
  r'\u{',
  r'\u{41}',
  '\u{1F600}',
  '{title:',
  '{start_of_chorus}',
  '{end_of_chorus}',
  '{start_of_tab}',
  '{end_of_tab}',
  '{soc}',
  '{eoc}',
  '{sov-guitar}',
  '{new_song}',
  '{ns}',
  '{chorus}',
  '{define:',
  '{image:',
  '{meta:',
  '{comment:',
  '{colb}',
  '{start_of_',
  '{end_of_',
  '{transpose:',
  '{capo:',
  '{key:',
  '{x_ext:',
  '[C]',
  '[*note]',
  '[^]',
  '[]',
  '[ ]',
  '[|]',
  '#',
];

String _randomSource(Random random) {
  final buffer = StringBuffer();
  final parts = random.nextInt(40);
  for (var i = 0; i < parts; i++) {
    buffer.write(_fragments[random.nextInt(_fragments.length)]);
  }
  return buffer.toString();
}

void main() {
  group('parsing is total', () {
    test('random input never throws and always yields a song', () {
      const seed = 20260919;
      final random = Random(seed);
      for (var i = 0; i < 5000; i++) {
        final source = _randomSource(random);
        late ParseResult result;
        expect(
          () => result = ChordPro.parse(source),
          returnsNormally,
          reason: 'seed $seed, iteration $i, source ${source.codeUnits}',
        );
        expect(
          result.songs,
          isNotEmpty,
          reason: 'seed $seed, iteration $i, source ${source.codeUnits}',
        );
        // Every downstream accessor must be safe on whatever came back.
        for (final song in result.songs) {
          expect(song.metadata.isEmpty, isA<bool>());
          for (final section in song.sections) {
            section
              ..gridAttributes
              ..textblockAttributes;
            for (final line in section.lines) {
              expect(line.span.line, greaterThan(0));
              expect(line.span.column, greaterThan(0));
            }
          }
          // And so must the transforms.
          expect(() => song.transposed(7), returnsNormally);
          expect(() => song.transposed(-5), returnsNormally);
        }
      }
    });

    test('parsing the same random input twice gives equal results', () {
      // Parsing is a pure function of its input, which the new value
      // equality now lets us assert directly.
      final random = Random(7);
      for (var i = 0; i < 500; i++) {
        final source = _randomSource(random);
        expect(
          ChordPro.parse(source),
          ChordPro.parse(source),
          reason: 'source ${source.codeUnits}',
        );
      }
    });

    test('options do not make it throw either', () {
      final random = Random(99);
      for (var i = 0; i < 500; i++) {
        final source = _randomSource(random);
        expect(
          () => ChordPro.parse(
            source,
            selectors: {'guitar'},
            notesMode: true,
            strict: true,
            altBrackets: '«»',
            preprocessors: [(line) => line.replaceAll('x', 'y')],
          ),
          returnsNormally,
          reason: 'source ${source.codeUnits}',
        );
      }
    });
  });
}
