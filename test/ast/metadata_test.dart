import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('Metadata', () {
    test('collects titles, artists, and typed scalars', () {
      const source = '''
{title: Song A}
{t: Song A Alt}
{artist: Alice}
{artist: Bob}
{year: 2024}
{capo: 3}
{key: D}
''';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.titles, ['Song A', 'Song A Alt']);
      expect(song.metadata.artists, ['Alice', 'Bob']);
      expect(song.metadata.year, 2024);
      expect(song.metadata.capo, 3);
      expect(song.metadata.key, 'D');
    });

    test('desugars {meta: key value} into typed fields', () {
      const source = '{meta: artist Carol}\n{meta: year 1999}';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.artists, ['Carol']);
      expect(song.metadata.year, 1999);
    });

    test('routes unknown metadata names into other', () {
      final song = ChordPro.parseSong('{mood: calm}\n{mood: bright}');
      expect(song.metadata.other['mood'], ['calm', 'bright']);
    });

    test('ignores non-integer values for int fields', () {
      final song = ChordPro.parseSong('{year: not-a-year}');
      expect(song.metadata.year, isNull);
    });

    test('isEmpty on a directive-less document', () {
      final song = ChordPro.parseSong('plain lyrics with no directives');
      expect(song.metadata.isEmpty, isTrue);
    });

    test('captures sortartist scalar', () {
      final song = ChordPro.parseSong('{sortartist: Dylan, Bob}');
      expect(song.metadata.sortArtist, 'Dylan, Bob');
      expect(song.metadata.isEmpty, isFalse);
    });

    test('collects tag list in source order', () {
      const source = '{tag: holiday}\n{tag: acoustic}';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.tags, ['holiday', 'acoustic']);
    });

    test('collects arranger list in source order', () {
      const source = '{arranger: Alice}\n{arranger: Bob}';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.arrangers, ['Alice', 'Bob']);
    });

    test('{meta: arranger …} desugars into arrangers list', () {
      final song = ChordPro.parseSong('{meta: arranger Eve}');
      expect(song.metadata.arrangers, ['Eve']);
    });

    test('arranger populates isEmpty to false', () {
      final song = ChordPro.parseSong('{arranger: Dave}');
      expect(song.metadata.isEmpty, isFalse);
    });

    test('reserves auto-generated meta names from .other', () {
      const reserved = [
        '_key',
        'key.print',
        'key.sound',
        'key_actual',
        'key_from',
        'today',
        'songindex',
        'songsource',
        'chords',
        'numchords',
        'pages',
        'pageno',
        'page.class',
        'page.side',
        'chordpro',
        'chordpro.version',
        'chordpro.songsource',
      ];
      for (final name in reserved) {
        final song = ChordPro.parseSong('{meta: $name colliding}');
        expect(
          song.metadata.other.containsKey(name),
          isFalse,
          reason: '$name must not be writable from {meta:}',
        );
      }
    });

    test('keeps x_ custom extensions out of metadata.other', () {
      const source = '{x_myapp_id: 42}\n{mood: bright}';
      final song = ChordPro.parseSong(source);
      expect(song.metadata.other, {
        'mood': ['bright'],
      });
      expect(
        song.customExtensions.map((d) => d.name).toList(),
        ['x_myapp_id'],
      );
    });
  });
}
