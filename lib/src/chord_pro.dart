import 'package:chord_pro/src/models/metadata.dart';
import 'package:chord_pro/src/models/song.dart';
import 'package:chord_pro/src/utils/parse.dart';

/// The entry point of the ChordPro library.
class ChordPro {
  /// Process content of the ChordPro string
  /// Return [Song] with all retrieved info from the content
  static Song parseSong(String song) {
    final directiveMap = directiveParse(song);

    final metadada = Metadata.fromMap(directiveMap);
    return Song(
      metadata: metadada,
    );
  }
}
