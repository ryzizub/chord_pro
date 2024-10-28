import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

import 'utils/utils.dart';

void main() {
  group('Chordpro', () {
    test('parse metadata', () async {
      final song = ChordPro.parseSong(getTestSongBody());
      expect(song.metadata?.title, "Knockin' on Heaven's Door");
    });
  });
}
