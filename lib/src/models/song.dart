import 'package:chord_pro/src/models/metadata.dart';
import 'package:chord_pro/src/models/preamble.dart';

/// The entry point of the Song
class Song {
  /// Song information
  Song({
    this.metadata,
    this.preamble,
  });

  /// Associated preamble of the song
  final Preamble? preamble;

  /// Associated metadata of the song
  final Metadata? metadata;
}
