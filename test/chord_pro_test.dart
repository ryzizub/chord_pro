import 'dart:io';

import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('ChordPro.parse', () {
    test('returns a single (empty) song for empty input', () {
      final result = ChordPro.parse('');
      expect(result.songs, hasLength(1));
      expect(result.songs.single.metadata.isEmpty, isTrue);
      expect(result.diagnostics, isEmpty);
    });

    test('splits on {new_song}', () {
      const source = '''
{title: First}
{new_song}
{title: Second}
''';
      final result = ChordPro.parse(source);
      expect(result.songs, hasLength(2));
      expect(result.songs[0].metadata.titles, ['First']);
      expect(result.songs[1].metadata.titles, ['Second']);
    });

    test('splits on {ns} short form', () {
      const source = '{title: A}\n{ns}\n{title: B}';
      final result = ChordPro.parse(source);
      expect(result.songs, hasLength(2));
      expect(result.songs[1].metadata.titles, ['B']);
    });

    test('preserves directives in source order', () {
      const source = '{title: X}\n{capo: 2}\n{artist: Y}';
      final song = ChordPro.parseSong(source);
      expect(
        song.directives.map((d) => d.name).toList(),
        ['title', 'capo', 'artist'],
      );
    });

    test('parses the example file', () {
      final source =
          File('example/knockin_on_heavens_door.cho').readAsStringSync();
      final song = ChordPro.parseSong(source);
      expect(song.metadata.titles.single, "Knockin' on Heaven's Door");
      expect(song.metadata.artists, ['Bob Dylan']);
      expect(song.metadata.key, 'G');
      expect(song.metadata.tempo, 68);
    });
  });
}
