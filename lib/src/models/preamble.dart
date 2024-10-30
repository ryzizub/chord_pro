import 'package:chord_pro/src/models/directive.dart';

/// The entry point of the Preamble
class Preamble with DirectiveMixin<Preamble> {
  /// Holds preamble info the song like [newSong] etc.
  Preamble({
    this.newSong = false,
  });

  /// Creates instance of [Preamble] from created map of already
  /// parsed content of Chordpro
  factory Preamble.fromDirectiveMap(Map<String, List<String>> map) {
    final newSong = (map['new_song'] ?? map['ns']) != null;

    return Preamble(
      newSong: newSong,
    );
  }

  /// This directive indicates that the current song,
  /// if any, is complete and that a new song will follow
  final bool newSong;

  @override
  bool isEmpty() {
    return !newSong;
  }
}
