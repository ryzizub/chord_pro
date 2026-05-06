import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

void main() {
  group('{ns}/{new_song} toc attribute (ChordPro 6.040)', () {
    test('{ns toc=no} on second song suppresses it', () {
      const src = '{title: First}\n[C]Hi\n{ns toc=no}\n{title: Second}\n[D]Bye';
      final r = ChordPro.parse(src);
      expect(r.songs, hasLength(2));
      expect(r.songs[0].tocSuppressed, isFalse);
      expect(r.songs[1].tocSuppressed, isTrue);
    });

    test('{ns toc=yes} explicit yes', () {
      const src = '{title: A}\n{ns toc=yes}\n{title: B}';
      expect(ChordPro.parse(src).songs[1].tocSuppressed, isFalse);
    });

    test('bare {ns} -> tocSuppressed=false', () {
      const src = '{title: A}\n{ns}\n{title: B}';
      expect(ChordPro.parse(src).songs[1].tocSuppressed, isFalse);
    });

    test('first song never suppressed', () {
      const src = '{title: A}\n[C]Hi';
      expect(ChordPro.parseSong(src).tocSuppressed, isFalse);
    });

    test('{ns toc=false} also suppresses', () {
      const src = '{title: A}\n{ns toc=false}\n{title: B}';
      expect(ChordPro.parse(src).songs[1].tocSuppressed, isTrue);
    });

    test('{ns toc=0} also suppresses', () {
      const src = '{title: A}\n{ns toc=0}\n{title: B}';
      expect(ChordPro.parse(src).songs[1].tocSuppressed, isTrue);
    });
  });
}
