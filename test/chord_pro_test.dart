import 'package:chord_pro/chord_pro.dart';
import 'package:test/test.dart';

import 'utils/utils.dart';

void main() {
  group('Chordpro', () {
    test('parse example song', () async {
      final song = ChordPro.parseSong(getTestSongBody());
      expect(song.preamble, null);
      expect(song.metadata?.title, ["Knockin' on Heaven's Door"]);
      expect(song.metadata?.artist, ['Bob Dylan']);
    });
  });
}
